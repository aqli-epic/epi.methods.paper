clear all
set type double
set more off
set matsize 4000
pause on

local root "C:/Users/Aarsh/Desktop/methods_paper/methods_paper"
local rr_dset = "`root'/data/raw/gemm_rr.csv"
local mr_dset = "`root'/data/raw/IHME-GBD_2019_DATA-0567e3e4-1.csv"
local outdir = "`root'/output"
local tempdir = "`root'/data/intermediate"
local gemm_lx = "`root'/data/intermediate/gemm_life_expectancy.dta"
local gemm_lx_csv = "`root'/data/intermediate/gemm_life_expectancy.csv"


/*---------------------------------------------------------------------------*/
* Notes about the Global Exposure Mortality Model in Burnett et al. (2018)
* Focus primarily on 15 cohorts examining long-term exposure and mortality. 
* 1 cohort is a study of Chinese men w/ exposures up to 84.
* Focus on non-accidental deaths (nearly all due to non-communicable diseases)
* and lower respiratory infections.
* Complimented with data from 26 additional cohorts (in which no access to
* subject level info).
* GEMM estimated as a common (possibly nonlinear) hazard ratio model among
* the 41 cohorts by pooling predictions of the hazard ratio among cohorts over
* their range of exposure.
/*---------------------------------------------------------------------------*/


/*---------------------------------------------------------------------------*/
* Part 1. Prepare files
/*---------------------------------------------------------------------------*/

* Load Burnett et al. (2018) GEMM parameter estimates by cause of death, with
* inclusion of Chinese Male Cohort (Yin et al. 2018) from Table S2.
* Load GBD mortality rates for: (1) ischemic heart disease (IHD); (2) stroke;
* (3) chronic obstructive pulmonary disease (COPD); (4) lung cancer; (5) LRIs;
* and (6) Non-communicable diseases.
* Adjust mortality rates using RR (at global average PM2.5).

* choices
local ncdlri = 0 // GEMM NCD + LRI = 1 ; GEMM 5-COD = 0
local mr_yr = 2016
local global_avg_PM = 45.479 // global population-weighted average PM2.5
local tmrel = 2.4

tempfile rr_dset_modified file1 file2 file3 509 426 322 493 494 9999 raw allcause


/*---------------------------------------------------------------------------*/
* (a) Load RR data from Burnett et al. (2018), Table S2.
	insheet using "`rr_dset'", clear names
	
	* coercing all columns from class "string" to class "numeric"
	foreach var in agerangeyears theta theta_se alpha mu nu {
		destring `var', replace
	}
	
	* encode cause variable in consistent manner with gbd IER data
	rename Cause riskoutcome
	gen cause = 0
	
	* bring the "cause" column to the front
	order cause, first
	
	* encode the cause column
	replace cause = 509 if riskoutcome == "Chronic obstructive pulmonary disease"
	replace cause = 493 if riskoutcome == "Ischaemic heart disease"
	replace cause = 322 if riskoutcome == "Lower respiratory infections"
	replace cause = 494 if riskoutcome == "Stroke "
	replace cause = 426 if riskoutcome == "Lung cancer"
	replace cause = 9999 if riskoutcome == "Non-communicable disease and lower respiratory infections"
	
	* drop the risk outcome column
	drop riskoutcome
	
	* add labels to the cause id's and then link it to the cause name. In R, its equivalent to keeping both cause id and cause name columns.
	lab define cause_lab 	509	"Chronic obstructive pulmonary disease" ///
							493 "Ischaemic heart disease" ///
							322 "Lower respiratory infections" ///
							494 "Stroke" ///
							426 "Tracheal, bronchus, and lung cancer" ///
							294 "All causes" ///
							409 "Non-communicable diseases" ///
							9999 "NCD & LRI"
	lab val cause cause_lab
	
	* save this new dataset and name it "raw"
	save "`raw'", replace

	* for each cause, expand rows into consistent format

	* Assumption: causes: 509, 426, 322: these are the causes for which we do not have age-wise/pm-level information, i.e. just a single row in the "raw" dataset. So, for each of these causes, we will assign their exact same information to age intervals starting from 25 and going to 95+, i.e. we are assuming that all of the information available for each of these causes stays the same for all age groups. Then, we will take the output of that process and assign it to pm levels starting from 1 to 120 micrograms per cubic meter. So, each pm level will have that exact same information.
	
	foreach c in 509 426 322 {
		use `raw', clear	
		keep if cause==`c'

		* generate consistent age brackets
		gen age=25
		foreach n in 30 35 40 45 50 55 60 65 70 75 80 85 90 95 {
			local m = `n'-5
			expand 2 if age==`m'
			replace age=`n' if age[_n-1]==`m'
		}
		drop agerangeyears

		* generate consistent pm brackets and assign each of those brackets the above information.
		gen pm_level=.
		replace pm_level=0
		gen count=_n
		expand 2 if pm_level==0
		forval n = 1/122 {
			local m = `n'-1
			replace pm_level=`n' if count==1 & count[_n-1]==15 & pm_level[_n-1]==`m'
			replace pm_level=`n' if pm_level[_n-1]==`n'
			expand 2 if pm_level==`n'
		}
		drop if pm_level==122
		drop count
		
		* GEMM(z)=exp{θlog(z/α+1)/(1+exp{-(z-μ)/ν})}, where z=max(0, PM2.5-2.4μg/m3)
		* apply the above formula and create additional columns: x, z, age_, in this "age_" column will be the relative risks column.
		gen x=pm_level-`tmrel'
		gen z=.
		replace z=max(0, x)
		gen age_=exp(theta*log(z/alpha+1)/(1+exp(-(z-mu)/nu)))
        
		* keep relevant columns and reshape the dataset, such that each of the age intervals are the columns and relative risk information is the actual data. Then save the temporary dataset locally as "[causeidno].dta". 
		keep cause pm_level age age_
		reshape wide age_, i(pm_level) j(age)
		order cause pm_level age_*
		save "`c'", replace
	}

	* causes: 493, 494, 9999: For these causes, we have age wise data, but the age brackets are a little different, for e.g. 27.5 instead of 25. So, the first step is to round down the age intervals to ones that fit our format, which starts from 25 and goes till 95+ and assign the same data as was assigned to their nearest age bracket, so data for "27.5" would be assigned to "25", data for "32.5" will be assigned to "30". Also, because our format contains more age brackets than is available in the data provided by the authors, so the last 3 age brackets, i.e. 85, 90, 95, will get the same value as the "80" age bracket. Then each of the pm brackets will be assigned the exact same dataset. In total there are 122 pm levels and each of these levels will be assigned, the same age-bucketed dataset. After that we will reshape it to wide, similar to what we did in the above cause list.
	foreach c in 493 494 9999{
		use `raw', clear	
		keep if cause==`c'
	
		* generate consistent age brackets
		gen age=agerangeyears-2.5
		replace age=80 if age==82.5
		expand 4 if age==80
		replace age=85 if age[_n-1]==80
		replace age=90 if age[_n-1]==85
		replace age=95 if age[_n-1]==90
		drop agerangeyears

		* generate consistent pm brackets and assign each of those brackets the above information.
		gen pm_level=.
		replace pm_level=0
		gen count=_n
		expand 2 if pm_level==0
		forval n = 1/122 {
			local m = `n'-1
			replace pm_level=`n' if count==1 & count[_n-1]==15 & pm_level[_n-1]==`m'
			replace pm_level=`n' if pm_level[_n-1]==`n'
			expand 2 if pm_level==`n'
		}
		drop if pm_level==122
		drop count

		* GEMM(z)=exp{θlog(z/α+1)/(1+exp{-(z-μ)/ν})}, where z=max(0, PM2.5-2.4μg/m3): apply this formula after generating a couple new columns.

		gen x=pm_level-`tmrel'
		gen z=.
		replace z=max(0, x)
		gen age_=exp(theta*log(z/alpha+1)/(1+exp(-(z-mu)/nu)))
		
		* reshape the dataset
		keep cause pm_level age age_
		reshape wide age_, i(pm_level) j(age)
		order cause pm_level age_*
		save "`c'", replace	
	}
	
	* append datasets for all individual causes
	use "509.dta", clear	
	foreach c in 426 322 493 494 9999 {
		append using `c'
	}

	reshape long age_, i(cause pm_level) j(age_interval_lower)
	rename age_ relative_risk

	count if cause == 426 & age_interval == 25
	local num_pm_cc = `r(N)'
	di "Number of PM concentrations: `num_pm_cc'"

	reshape wide relative_risk, i(cause age_interval_lower) j(pm_level)
	isid cause age_interval_lower
	save `"`rr_dset_modified'"', replace

/*---------------------------------------------------------------------------*/
* (b) Load mortality data.

	insheet using "`mr_dset'", comma clear
	keep if year==`mr_yr'

	rename val mortal_rate
	drop upper lower

	* encode cause variable for consistency
	gen cause = 0
	replace cause = 294 if cause_name == "All causes"
	replace cause = 509 if cause_name == "Chronic obstructive pulmonary disease"
	replace cause = 493 if cause_name == "Ischemic heart disease"
	replace cause = 322 if cause_name == "Lower respiratory infections"
	replace cause = 494 if cause_name == "Stroke"
	replace cause = 426 if cause_name == "Tracheal, bronchus, and lung cancer"
	replace cause = 409 if cause_name == "Non-communicable diseases"
	lab val cause cause_lab

	* adjust value format for age_name, rename to agegroup
	replace age_name = "0 to 5" if age_id == 1 // Under 5
	replace age_name = "0 to 1" if age_id == 28 // <1
	replace age_name = "0 to 20" if age_id == 158 // <20
	gen age_interval_lower = .
	label var age_interval_lower "lower bound"
	replace age_interval_lower = real(substr(age_name, 1, ///
			strpos(age_name, " to")-1))
	replace age_interval_lower = 95 if age_id == 235 // 95+ years
	replace age_interval_lower = 80 if age_id == 21 // 80+ years
	sort cause age_interval_lower

	rename age_name agegroup
	replace agegroup = subinstr(agegroup, "to", "-", .)
	replace agegroup = subinstr(agegroup, "plus", "+", .)
	replace agegroup = subinstr(agegroup, " ", "", .)
	replace agegroup = "<1" if agegroup == "0-1"

	* categorize agegroups
	gen age_n = substr(agegroup, 1, strpos(agegroup, "-") - 1)
	destring age_n, replace
	gen age_cat = ., after(agegroup)
	replace age_cat = 1 if agegroup == "<1"
	replace age_cat = 2 if agegroup == "1-4"
	replace age_cat = (age_n/5) + 2 if age_cat == . & agegroup != "95+"
	qui summ age_cat
	replace age_cat = `r(max)' + 1 if agegroup == "95+"
	drop age_n
	qui summ age_cat
	local max_age_cat = `r(max)'
	di "Number of age categories: `max_age_cat'"

	* determine age gap
	gen age_gap = 5, after(age_cat) // inclusive
	replace age_gap = 1 if age_cat == 1
	replace age_gap = 4 if age_cat == 2
	replace age_gap = . if age_cat == `max_age_cat'

	keep location_name agegroup age_gap age_cat year mortal_rate cause age_interval_lower
	order year cause location_name agegroup age_gap age_cat age_interval_lower mortal_rate
	
	* save the "all causes" dataset
	*preserve
	*keep if inlist(cause, 294)
	*sort age_cat
	*save `"`allcause'"', replace
	

	* filter according to "GEMM NCD + LRI" or "GEMM 5-COD"	
	if `ncdlri' == 1 {
		keep if inlist(cause, 322, 409)
		collapse (sum) mortal_rate, by(year location_name age*)
		gen cause = 9999
		lab val cause cause_lab
		sort age_cat
	}
	if `ncdlri' == 0 {
		drop if inlist(cause, 409, 294)
	}	

/*---------------------------------------------------------------------------*/
* (c) Merge.

	merge m:1 cause age_interval_lower using "`rr_dset_modified'"
	drop if _merge==2
	drop _merge

	reshape long relative_risk, i(cause age_* mortal_rate) j(pm_level)
	sort cause pm_level age_interval_lower

	* assign relative risk = 1 if age < 25 
	replace relative_risk = 1 if age_interval_lower < 25 & missing(relative_risk)

/*---------------------------------------------------------------------------*/
* (d) Adjust mortality rates, using RR at the global average PM2.5 level.

	di "Global population-weighted average PM2.5 level: `global_avg_PM'"

	* Find avg pm level that is closest to the global pop-weighted avg
	if `global_avg_PM' <= 30 {
		local global_avg_PM = round(`global_avg_PM', 5)
	}
	else if `global_avg_PM' <= 150 {
		local global_avg_PM = round(`global_avg_PM', 15)
	}
	else if `global_avg_PM' <= 200 {
		local global_avg_PM = round(`global_avg_PM', 50)
	}
	else {
		local global_avg_PM = round(`global_avg_PM', 100)
	}
	di "Rounded global pop-weighted average PM2.5 level: `global_avg_PM'"

	sort cause age_cat pm_level

	gen temp = .
	by cause age_cat: replace temp = relative_risk ///
			if pm_level == `global_avg_PM'
	by cause age_cat: egen rr_normalizer = mean(temp)
	drop temp
	gen adjusted_mortal_rate = mortal_rate * relative_risk / rr_normalizer
	
	save `file1', replace

/*---------------------------------------------------------------------------*/
* (e) Prep "all-cause" mortality rates (for actual lifetables), adjusted.  

	use `file1', clear

	* sum across selected causes of death
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
	lab var nMx "Mortality rate (deaths per person-year)"

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
	replace nqx = 1 if age_cat == `max_age_cat'
	lab var nqx "Probability of death during the age interval (x, x+n)"

	* compute lx
	sort pm_level age_cat
	gen lx = 100000
	lab var lx "Population of cohort still alive at the beginning of age interval"
	forval i = 2/`max_age_cat' {
	by pm_level: replace lx = lx[_n - 1] * (1 - nqx[_n - 1]) if age_cat == `i'
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
	}
	
	* compute e_x
	gen e_x = nTx / lx
	replace e_x = round(e_x,0.000001)
	
	* compute life expectancy at birth
	local actual_life_ex_birth = e_x[1]
	di "Glocal estimated life expectancy at birth: `actual_life_ex_birth'"
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
	rename pm_level pm_gemm
	
	sort id

	save `"`gemm_lx'"', replace
	outsheet using `"`gemm_lx_csv'"', comma replace





























