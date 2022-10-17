clear all
set type double
set more off
set matsize 4000
pause on

* setting the GBD year for which this analysis is performed
local mr_yr = 2019
di `mr_yr'

* IER 2016: five causes of death; 47.9 global PM2.5 average (in Apte et al. 2018).
* IER 2019: 32.656699 global PM2.5 average (2019, latest data); six causes of death.

* setting directories
local root = "C:/Users/Aarsh/Desktop/methods_paper/methods_paper"
local rr_dset = "`root'/data/raw/ier_rr_`mr_yr'.csv"
local mr_dset = "`root'/data/raw/IHME-GBD_2019_DATA-ef8a3562-1.csv"
local outdir = "`root'/output"
local ier_lx = "`root'/data/intermediate/ier_`mr_yr'_life_expectancy.dta"
local ier_lx_csv = "`root'/data/intermediate/ier_`mr_yr'_life_expectancy.csv"

* setting the global average PM2.5 value based on the underlying GBD paper. This is probably based on the * latest color file for that year, but not entirely sure.
if `mr_yr' == 2016 {
	local global_avg_PM = 47.9 // global population-weighted average PM2.5 in 2019
}
else if `mr_yr' == 2019 {
	local global_avg_PM = 32.656699 // global population-weighted average PM2.5 in 2019
}	

* displaying variables for sanity check
di `global_avg_PM'
di "`root'"
di "`rr_dset'"
		
* 2016, global population weighted average PM2.5, according to latest no dust no sea salt data: 34.16829 
* 2016, global population weighted average PM2.5, according to Apte et al. (2018): 47.9 

/*---------------------------------------------------------------------------*/
* Part 1. Prepare files
/*---------------------------------------------------------------------------*/

tempfile rr_dset_modified file1 file2 file3 allcause

/*---------------------------------------------------------------------------*/
* Load GBD relative risks: particulate matter air pollution, 5 disease channels
* Available at: http://ghdx.healthdata.org/record/ihme-data/gbd-2016-relative-risks
	
	* read in the csv file
	insheet using "`rr_dset'", clear names
	
	* create a pm_level with "micrograms per cubic meter" sign removed
	gen temp_pm_level = substr(units, 1, strpos(units, " ") - 1)
	
	* convert from string to numeric
	destring temp_pm_level, generate(pm_level)
	
	* moving the pm_level column to the front, similar to using "select" in R to move around columns
	order pm_level, after(risk)
	
	* drop redundant columns
	drop units temp_pm_level
	
	* rename "years" column to "v17", because its actually not "years"
	rename years v17
	
	* Remove all the confidence level information from all the relative risks columns and store this "confidence interval removed" information in corresponding new columns, and convert them from string to numeric. Old age category columns were named as v3, v4... v17. The new "CI removed" information columns will be temporarily as "v3_float, v4_float... v17_float". In the next step, we will give them actual age names.
	foreach age_strata of varlist `allages_cat' v* {
		gen temp_`age_strata' = substr(`age_strata', 1, strpos(`age_strata', "(") - 1)
		destring temp_`age_strata', generate(`age_strata'_float)
		drop temp_`age_strata'
	}
	
	* rename, starting from "v3_float" column and rename all other "v'x'_float" type columns. So, for example: "v3_float" will be changes to "age_25", which means it represents the age category 25-29. Similarly, "v4_float" will be changed to "age_30", and will represent the age_cateogory 30-34, and so on till v1_float which will represent the final age category, which is "95+".
	local y = 25
	foreach age_strata of varlist v3_float-v17_float {
		rename `age_strata' age_`y'
		local lower_b = `y'
		local upper_b = `y' + 4
		label var age_`y' "Relative risk for age `lower_b' - `upper_b'"
		local y = `y' + 5
	}
	
	* add label to the final age category
	label var age_95 "Relative risk for age 95+" 
	
	* remove redundant temporary columns and keep only relevant columns
	keep risk age_*  pm_level
	
	* rename "risk" column to "cause_name"
	rename risk cause_name

	* encode cause variable for consistency, i.e. create a new column called "cause" that will map each "cause_name" to a corresponding identfier number, which most likely remains same for all GBD datasets.
	gen cause = 0
	replace cause = 294 if cause_name == "All causes"
	replace cause = 509 if cause_name == "Chronic obstructive pulmonary disease"
	replace cause = 493 if cause_name == "Ischaemic heart disease"
	replace cause = 322 if cause_name == "Lower respiratory infections"
	replace cause = 494 if cause_name == "Stroke" | cause_name == "Cerebrovascular disease"
	replace cause = 426 if cause_name == "Tracheal, bronchus, and lung cancer"
	replace cause = 409 if cause_name == "Non-communicable diseases"
	replace cause = 587 if cause_name == "Diabetes mellitus type 2"
	
	* add a label definition for each cause id number
	lab define cause_lab 	509	"Chronic obstructive pulmonary disease" ///
							493 "Ischaemic heart disease" ///
							322 "Lower respiratory infections" ///
							494 "Stroke" ///
							426 "Tracheal, bronchus, and lung cancer" ///
							294 "All causes" ///
							409 "Non-communicable diseases" ///
							587 "Diabetes mellitus type 2" ///
							9999 "NCD & LRI"
	
	* we attached a value label to causes and now that new "cause" column contains the cause_names and also labels for what each of its values mean.
	lab val cause cause_lab
	
	* We drop the cause_name column here, because in the above "lab" command, we attached a value label to causes and now that new "cause" column contains the cause_names and also labels for what each of its values mean.
	drop cause_name

	* reshape the dataset to long format, so that we can bring the "age_x" multiple columns into a single "age_interval_lower" column which would contain the lower limit of the age column.
	reshape long age_, i(cause pm_level) j(age_interval_lower)
	
	* rename the "age_" column to "relative risk", because post reshaping that is what the "age_" column stores.
	rename age_ relative_risk

	* count the total number of rows with cause == "All causes" and age interval: 25-29. I did, the count = 0.
	count if cause == 294 & age_interval == 25
	
	* Why was this necessary here? Is it just a sanity check?
	local num_pm_cc = `r(N)'
	di `num_pm_cc'
	di "Number of PM concentrations: `num_pm_cc'"

	* reshape for convenient merge later
	reshape wide relative_risk, i(cause age_interval_lower) j(pm_level)
	isid cause age_interval_lower
	
	* I had to initiate the "tempfile" here separately to save "rr_dset_modified" in it, even though up top I have added it as a tempfile.
	*tempfile rr_dset_modified
	save "`rr_dset_modified'", replace

/*---------------------------------------------------------------------------*/
* (b) Load GBD all-causes mortality data.
	
	* load in the mortality rates dataset
	insheet using "`mr_dset'", comma clear
	
	* The above dataset has data on multiple years. But, we only want to focus on year stored in the "mr_yr" macro, which for now is 2019.
	keep if year==`mr_yr'

	* rename the column "val" to "mortal_rate"
	rename val mortal_rate
	
	* dropping the "confidence interval around mortality rates" column
	drop upper lower

	* encode cause variable for consistency, i.e. create a new column called "cause" that will map each "cause_name" to a corresponding identfier number.
	gen cause = 0
	replace cause = 294 if cause_name == "All causes"
	replace cause = 509 if cause_name == "Chronic obstructive pulmonary disease"
	replace cause = 493 if cause_name == "Ischemic heart disease"
	replace cause = 322 if cause_name == "Lower respiratory infections"
	replace cause = 494 if cause_name == "Stroke"
	replace cause = 426 if cause_name == "Tracheal, bronchus, and lung cancer"
	replace cause = 409 if cause_name == "Non-communicable diseases"
	replace cause = 587 if cause_name == "Diabetes mellitus type 2"
	
	* Where does "cause_lab" come from?
	lab val cause cause_lab

	* adjust value format for age_name, rename to agegroup
	
	* replace "Under 5" with "0 to 5"
	replace age_name = "0 to 5" if age_id == 1 // Under 5
	
	*replace "<1" with "0-1"
	replace age_name = "0 to 1" if age_id == 28 // <1
	
	* replace "<20" with "0-20"
	replace age_name = "0 to 20" if age_id == 158 // <20
	
	* add a new blank column called "age_interval_lower". It will store the lower limits of age categories.
	gen age_interval_lower = .
	
	* add a label to the newly created column
	label var age_interval_lower "lower bound"
	
	* extracting the lower limit of the age interval
	replace age_interval_lower = real(substr(age_name, 1, ///
			strpos(age_name, " to")-1))
			
	* for some other categories that do not fit the above pattern, add "age_interval_lower" manually
	replace age_interval_lower = 95 if age_id == 235 // 95+ years
	replace age_interval_lower = 80 if age_id == 21 // 80+ years

	* sort to bring dataset and cause wise age intervals in order
	sort cause age_interval_lower

	* rename "age_name" column
	rename age_name agegroup
	
	* removing the "to's'" in the age categories and replacing them with "-"'s 
	replace agegroup = subinstr(agegroup, "to", "-", .)
	replace agegroup = subinstr(agegroup, "plus", "+", .)
	replace agegroup = subinstr(agegroup, " ", "", .)
	
	* replace "<1" age_group to "0-1"
	replace agegroup = "<1" if agegroup == "0-1"

	* categorize agegroups
	
	* create a age_n column which is similar to age_interval_lower
	gen age_n = substr(agegroup, 1, strpos(agegroup, "-") - 1)
	
	* change it from "string" to "numeric"
	destring age_n, replace
	
	* create a new column called "age_cat" after the "agegroup" column.
	gen age_cat = ., after(agegroup)
	
	* For example: for the first age interval, which is "<1", the age_cat would be "1". Similarly, for the third age interval, which is "5-9", the age category would be 3.
	replace age_cat = 1 if agegroup == "<1"
	replace age_cat = 2 if agegroup == "1-4"
	
	* this line of code applies the above idea to all age intervals, and as a result correspondingly creates its age categories.
	replace age_cat = (age_n/5) + 2 if age_cat == . & agegroup != "95+"
	
	* summarise age category, just to see how many categories there are.
	summ age_cat
	
	* assign "95+" the highest age category number.
	replace age_cat = `r(max)' + 1 if agegroup == "95+"
	
	* this information is already contained in the age_interval_lower column
	drop age_n
	
	* summarise age category, just to see how many categories there are, which now should be one more than, when we did this same operation in line 227
	summ age_cat
	
	* storing the "max" age category, which as of now is "21". The "di" i.e. display command will show that.
	local max_age_cat = `r(max)'
	di `max_age_cat'
	di "Number of age categories: `max_age_cat'"

	* Creates an "age_gap" column that captures the interval length of a given age interval. For the first and last category it sets the gap manually
	* because it does not fit the general pattern, i.e. a gap of 5.
	gen age_gap = 5, after(age_cat) // inclusive
	
	* "<1" age category has an age gap of 1
	replace age_gap = 1 if age_cat == 1
	
	* "1-4" has an age gap of 4
	replace age_gap = 4 if age_cat == 2 
	
	* ?Shouldn't this be replace "age_gap == 5..."
	replace age_gap = . if age_cat == `max_age_cat'

	* Keep only columns that we will use moving forward.
	keep location_name agegroup age_gap age_cat year mortal_rate cause age_interval_lower
	
	* move around columns, bringing them in the below order.
	order year cause location_name agegroup age_gap age_cat age_interval_lower mortal_rate

	* ?preserve the all causes data for actual life table calculation and then restore it.
	* Note: The cause_id was mapped to cause_name up top, after which the cause_id column was dropped. But, its information was contained in the cause_name column, which is why we can access it here. Need to understand the data structure that allows for this in STATA.
	preserve
	* save global, all causes mortality rates for actual life table section 
	keep if inlist(cause, 294)
	sort age_cat
	save `"`allcause'"', replace
	restore

	* filter out everything except 6 main causes of death
	drop if inlist(cause, 294, 409)

/*---------------------------------------------------------------------------*/
* (c) Merge Mortality Rates and Relative Risks dataset

	* merge the cleaned mortality data, i.e. the master data, with the cleaned relative risks data, i.e. the using dataset. I did a sanity check and a "1:1" merge would also result in the same output.
	merge m:1 cause age_interval_lower using "`rr_dset_modified'"
	
	* drop all rows where there is data in the using dataset but not in the master dataset. When I was doing this analysis, there were no observations in the "_merge" == 2, category.
	drop if _merge==2
	
	* drop the final merge column, which just contains the information on what type of merge was performed.
	drop _merge

	* reshape the dataset back to long format, so that we have pm levels as a column
	reshape long relative_risk, i(cause age_* mortal_rate) j(pm_level)
	
	* arrange data in ascending order, based on the given column list
	sort cause pm_level age_interval_lower

	* assign relative risk = 1 if age < 25, we make this assumption because relative risks data for the 6 disease channels is available for age > 25. 
	replace relative_risk = 1 if age_interval_lower < 25 & missing(relative_risk)

/*---------------------------------------------------------------------------*/
* (d) Adjust mortality rates, using RR at the global average PM2.5 level.

	* creating a new "rr_normalizer" column that would help us create the "adjusted mortality rates" column
	di "Global population-weighted average PM2.5 level: `global_avg_PM'"

	* Find avg pm level in the current dataset pm_level column, that is closest to the global pop-weighted avg. This whole rounding process is trying to figure out the closest pm value "from the list of unique pm values in the current dataset's pm_level" column that is closest to the global average PM value that is set up top. We do this, because the value set up top is not a whole number. This is why in the next step we create a new column "temp"  and in it we store the relative risks data "grouped by cause and age" for a world where pm_level =  global average. We then assign each cause, age group the mean value of the relative risk for that group.  
	if `global_avg_PM' <= 30 {
		local global_avg_PM = round(`global_avg_PM', 5)
	}
	else if `global_avg_PM' <= 150 & `mr_yr'==2016 {
		local global_avg_PM = round(`global_avg_PM', 15)
	}
	else if `global_avg_PM' <= 150 & `mr_yr'==2019 {
		local global_avg_PM = round(`global_avg_PM', 10)
	}
	else if `global_avg_PM' <= 200 {
		local global_avg_PM = round(`global_avg_PM', 50)
	}
	else {
		local global_avg_PM = round(`global_avg_PM', 100)
	}
	di "Rounded global pop-weighted average PM2.5 level: `global_avg_PM'"

	sort cause age_cat pm_level
	
	* create a new column called "temp", which as of now only contains "."
	gen temp = .
	
	* for each cause, age_cat combination, replace the temp column with the relative risk number for that cause, age_cat combination, only where pm_level = rounded global average PM calculated above. Think of "by" command as group_by in R.
	by cause age_cat: replace temp = relative_risk ///
			if pm_level == `global_avg_PM'

	* for each cause, age_cat group, take the mean of the temp column, which as of now contains the relative risk number corresponding to the "global average PM2.5" for each cause, age_cat group.
	by cause age_cat: egen rr_normalizer = mean(temp)
	
	* drop the above "temp" column
	drop temp
	
	* add a new column called "adjusted mortality rate", which adjusts the mortality rate for a given age_cat, cause group, by their RR in relation to the RR at the rounded Global Average PM2.5 
	gen adjusted_mortal_rate = mortal_rate * relative_risk / rr_normalizer
	* "assuming that in the absence of this risk factor, age-specific death rates would be proportionally lower"
	
	save `file1', replace

/*---------------------------------------------------------------------------*/
* (e) Prep "all-cause" mortality rates (for actual lifetable computation)
* adjusted to reflect higher (or lower) mortality rates at PM concentrations that are
* higher (or lower) than the global average.  

	use `file1', clear

	* sum the "m_diff" column across selected causes of death grouped by age category and pm level columns
	gen m_diff = adjusted_mortal_rate - mortal_rate
	collapse (sum) m_diff, by(age_cat pm_level)
	sort age_cat

	merge age_cat using `allcause'
	drop _merge
	rename mortal_rate actual_mr
	* add differences to the global all-cause mortality rates
	gen nMx = actual_mr + m_diff
	keep agegroup age_cat age_gap agegroup pm_level nMx
	replace nMx = nMx / 100000
	lab var nMx "Mortality rate (deaths per person-year), adjusted"

	sort pm_level age_cat
	save `file2', replace

* (f) Prep age-specific mortalities attributed to PM2.5 (for cause-deleted).

	use `file1', clear

	gen paf = 1 - (1 / relative_risk)
	label var paf "Population attributable fraction (PAF)"

	* PAF is defined as the proportion of incidents in the population that are 
	* attributable to the risk factor (in this case, PM2.5).
	* Here, the PAF's reflect the deaths from going from 5 to [X] µg/m³, since 
	* I integrated the function shown in Figure 1 from 5 to [X]. 
	
	gen pm_mortal_rate = paf * adjusted_mortal_rate
	label var pm_mortal_rate "Mortality rate from PM2.5"
	
	collapse (sum) pm_mortal_rate, by(age_* pm_level)
	
	drop age_interval_lower
	rename pm_mortal_rate pm_nMx 
	replace pm_nMx = pm_nMx / 100000
	lab var pm_nMx "Mortality rate, all-causes, PM2.5 (deaths/person-year)"
	
	save `file3', replace				


/*---------------------------------------------------------------------------*/
* Part 2. Estimate actual and cause-deleted life tables
/*---------------------------------------------------------------------------*/

tempfile actual_table

/*---------------------------------------------------------------------------*/
* (a) Calculate "actual" global life table, for various PM2.5 levels

* Use adjusted all-cause mortality rates, based on Vodonos et al. (2018), to 
* compute actual life expectancy at birth in world where PM2.5 = X

	use `file2', clear

	* notes: the following computation is based on Apte et al. (2018) and 
	* Arias et al. (2013)

	* define alpha_x to be 0.5 for every age group (as in Apte et al.)
	gen alpha_x = 0.5
	lab var alpha_x "Frac of age interval duration that avg dying cohort member survives"
	* compute nqx
	* nqx = ndx/lx (Equation [3], Arias et al.). ndx is the number of life table deaths due to cause. lx is the number of survivors to age x.	
	gen nqx = (nMx * age_gap) / (1 + (nMx * age_gap * (1 - alpha_x)))
	di `max_age_cat'
	replace nqx = 1 if age_cat == `max_age_cat'
	lab var nqx "Probability of death during the age interval (x, x+n)"

	* compute lx
	sort pm_level age_cat
	gen lx = 100000
	lab var lx "Population of cohort still alive at the beginning of age interval"
	forval i = 2/`max_age_cat' {
	by pm_level: replace  lx = lx[_n - 1] * (1 - nqx[_n - 1]) if age_cat == `i'
	}
	
	* compute ndx
	gen ndx = lx * nqx
	lab var ndx "# life table cohort deaths in the interval"
	* compute nLx
	gen nLx = ndx / nMx
	lab var nLx "# life-years lived by cohort in the interval"
	
	* compute nfx (prep for part 2)
	* notes: ndx = lx - l_(x+n) from Equation [2] in Arias et al. 
	//gen nfx = ((age_gap * lx) - nLx) / ndx
	gen nfx = 0
	sort pm_level age_cat
	forval i = 1/`max_age_cat' {
		by pm_level: replace nfx = ((age_gap[_n] * lx[_n]) - nLx[_n]) / (lx[_n] - lx[_n+1]) ///
				if age_cat == `i'
	}
	
	* compute nTx
	gen nTx = nLx if age_cat ==`max_age_cat'
	local penultimate = `max_age_cat' - 1 
	sort pm_level age_cat
	forval i=1/`penultimate' {
		by pm_level: replace nTx = nLx[_n] + nTx[_n+1] if age_cat ==`max_age_cat'-`i'
		di nTx[_n + 1]
	}
	
	* compute e_x
	gen e_x = nTx / lx
	replace e_x = round(e_x,0.000001)
	
	* compute life expectancy at birth
	sum e_x if pm_level==`global_avg_PM' & age_cat==1
	local actual_life_ex_birth = `r(mean)'
	di "Global estimated life expectancy at birth: `actual_life_ex_birth'"
	* "In 2016, global the population-weighted median life expectancy at birth was 72.6 years"
	save `"`actual_table'"', replace


/*---------------------------------------------------------------------------*/
* (b) Calculate "cause-deleted" global life table, for various PM2.5 levels

	use `file3', clear

	* (i) following Apte et al., derive counterfactual prob of death
	* compute nqx_attrib
	gen alpha_x = 0.5 
	gen nqx_attrib = (pm_nMx * age_gap) / (1 + (1 - alpha_x)*(pm_nMx * age_gap))

	lab var nqx_attrib "Age-specific death rate attributed to PM2.5"
	* merge with nqx from "actual" lifetable
	merge m:1 age_cat age_gap pm_level using "`actual_table'", keepus(nMx nqx nfx e_x)
	keep if _merge==3
	drop _merge
	* compute nqx_deleted using nrx and nqx
	* nrx = nqx_attrib / nqx in Apte et al., which is equivalent to pm_nMx/nMx in Arias et al. [Eq. 6]
	gen nrx = pm_nMx / nMx
	gen nqx_del = 1 - ((1 - nqx)^(1 - nrx))
	lab var nqx_del "Counterfactual prob of death after eliminating PM2.5"
	
	* (ii) follow similar procedure (as above) to obtain cause-deleted life expectancy 
	gen lx_del = .
	lab var lx "(cause-deleted) Population of cohort still alive at the beginning of age interval"
	
	sort pm_level age_cat
	replace lx_del = 100000 if age_cat == 1
	forval i = 2/`max_age_cat' {
		by pm_level: replace lx_del = lx_del[_n - 1] * (1 - nqx_del[_n - 1]) ///
				if age_cat == `i' 
	}

	* compute nLx_del using nfx from part 1
	sort pm_level age_cat
	gen nLx_del = .
	forval i = 1/`max_age_cat' {
		by pm_level: replace nLx_del = ((age_gap[_n] - nfx[_n]) * ///
				lx_del[_n]) + (nfx[_n] * lx[_n+1]) if age_cat == `i'
	}

	* compute Tx_del
	gen Tx_del = .
	replace Tx_del = (e_x[_n] * lx_del[_n]) / (1 - nrx[_n]) ///
			if age_cat == `max_age_cat'
	sort pm_level age_cat
	forval i = `penultimate'(-1)1 {
		by pm_level: replace Tx_del = Tx_del[_n+1] + nLx_del[_n] ///
					 if age_cat == `i'
	}

	* compute counterfactual life expectancy
	gen counterfact_life_ex = Tx_del / lx_del
	replace counterfact_life_ex = round(counterfact_life_ex,0.000001)
	
	lab var counterfact_life_ex "Counterfactual life expectancy at age x "

	keep if age_cat == 1
	sort pm_level
	rename e_x actual_life_ex_birth
	gen life_year_lost = counterfact_life_ex - actual_life_ex_birth
	label var life_year_lost "Life year lost due to PM2.5 risk"
	assert life_year_lost >= 0
	
	keep pm_level actual_life_ex_birth counterfact_life_ex life_year_lost
	sort pm_level
	gen id=_n
	rename pm_level pm_ier_`mr_yr'
	
	sort id

	* manually adding a 120 datapoint (for fig 1b) 
	set obs 19
	replace pm_ier_2019 = 120 in 19
	sort pm_ier_2019
	replace actual_life_ex_birth=(actual_life_ex_birth[_n-1]+actual_life_ex_birth[_n+1])/2 if pm_ier_2019==120
	replace counterfact_life_ex=(counterfact_life_ex[_n-1]+counterfact_life_ex[_n+1])/2 if pm_ier_2019==120
	replace life_year_lost=counterfact_life_ex-actual_life_ex_birth if pm_ier_2019==120
	replace id=_n
		
	save `"`ier_lx'"', replace
	outsheet using `"`ier_lx_csv'"', comma replace



	
	







	
	


	

