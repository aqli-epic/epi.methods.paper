[33mcommit abda0556364261ff7da4236c2429321a5b05d737[m[33m ([m[1;36mHEAD -> [m[1;32mmaster[m[33m, [m[1;31morigin/master[m[33m)[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Nov 3 21:49:04 2022 +0530

    Changed the spelling of 'Ischaemic' to 'Ischemic' in all of the ier scripts in each instance and performed sanity checks. Now the ier scripts are working as expected. Also, the merge of the rr and mr dataset in 'gemm.3.calc_mortality_rates_and_lifetable_method' is successful.

[33mcommit e34b45d28a6bcdc86d8724037abee87f169f48a3[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Nov 3 17:01:42 2022 +0530

    Made cause_name spellings consistent across both the gemm relative risks cleaning file and the gemm mortality rates cleaning file. The differing spellings was messing up the merging of rr and mr datasets, but it is now fixed. The merge is successful and behaving as expected. This corresponds to the merge part of the code in the STATA legacy gemm script at line 276.

[33mcommit a877bf51d4abf4220617358459b60daa7c2a039d[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Nov 3 14:24:24 2022 +0530

    gemm mortality rates file prepped and exported two cleaned mortality rates dataset, one for NCD + LRI and the other for the 5 causes of deaths as listed in GEMM. Next step wis to start off with the mortality rates calculation, adjustment and life table method script.

[33mcommit 44561cfd353d8dfcd1c34ffcb9681eea3deaee84[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Nov 3 13:04:09 2022 +0530

    Also, fixed a bug in the age_gap generation part of the code in the mortality rates scripts for both ier gbd 2019 and gemm

[33mcommit 4bfea4f18adc4b7470b2a4f4267babd5c6e56e54[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Nov 3 13:02:33 2022 +0530

    Mortality rates prep process is in most part similar to the ier_gbd_2019 mortality rates preparation. The source of the data is still GBD, but in the causes of deaths we drop diabetes mellitus (which was part of the ier script) and add 'Non-communicable diseases'. So far, I have completed the following steps: renamed variables, added columns for age_gap and age_category, encoded cause_names, and made sure that it is consistent with the corresponding gemm relative risks file and also in general with the ier file.

[33mcommit 0ad811ab500a38d50762e044da91ca5401bbb3e9[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Tue Nov 1 14:01:18 2022 +0530

    Start prepping process for the mortality rates dataset

[33mcommit 6edcd23b986384a355d39e1c638a237dc2ffdc21[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Tue Nov 1 13:59:21 2022 +0530

    gemm relative risks dataset prep complete

[33mcommit 6c113d267f51098ff9afd51eeb9180f458c6e83e[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Tue Nov 1 13:13:59 2022 +0530

    gemm rr file prep continued: cause id's with single rows(493, 494, 9999) prep complete. Next step is to append all these individual cause wise datasets into a single relative risks dataset, which will correspond to the 'rr_dset_modified' in the legacy code.

[33mcommit b75ed0a680f1455652cda37b0a2061bbf196dab8[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Tue Nov 1 11:54:10 2022 +0530

    gemm rr file prep continued: cause id's with single rows(509, 426, 322) prep complete. Move on to prepping causes 493, 494, 9999 (similar to the corresponding step in the STATA legacy script).

[33mcommit fc9c3805a7860178ac528a283d042deeddeb9c4d[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Mon Oct 31 19:56:01 2022 +0530

    Prepping gemm relative risk file continue: all cause ids with single rows in the raw dataset (509, 426, 322), expanded and saved as separate datasets in a list. This corresponds to the for loop expanding process, that does this same thing but in a less elegant fashion.

[33mcommit a706a6270c37b171825cdc7306966a88d04ccdca[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Mon Oct 31 18:06:29 2022 +0530

    transitioned till gemm STATA script, 'save raw, replace' line

[33mcommit f257d5699ca8ad2427099648044cece666f36bad[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Sun Oct 30 23:54:02 2022 +0530

    adding 3 Rmd files for gemm model: cleaning relative risks, cleaning mortality rates, calculating mortality rates and life table calculations. Also added a STATA folder that contains the gemm do file, which I have started commenting.

[33mcommit 0188c2cea71685b021c920ca7c4b4c9b321600e8[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Oct 20 21:32:17 2022 +0530

    added a life years lost due to AQLI column. Added code for plotting 2 graphs. Graph 1 plots PM level versus Life Years Lost for both GBD (IER 2019) and AQLI. The second graph corresponds to this and plots PM level vs life years lost per microgram per cubic meter (i.e. this graph is the derivative of the first graph). Next step: prettify graphs, add more layers to this graph.

[33mcommit a3d19f03d758c86f80e9a5a626142270fb60a6c2[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Wed Oct 19 17:04:43 2022 +0530

    created final dataset for ier_2019 (which is a subset of 'cleaned_joined_mort_rr_data_long_summary_cdlt') for plotting and generate a 'life_years_lost' column (by taking the difference between the counterfactual and actual life expectancy column), which represents life years lost due to PM2.5 risk. Also generate a new 'row number' column in this final dataset.

[33mcommit e0e364aa1bdcf9c975533bb2e6bba04fda36c22c[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Wed Oct 19 16:20:34 2022 +0530

    Calculated counterfactual life expectancy at birth column

[33mcommit 6c7171a0adf4f1d7c3dffcb4bcd8060ec739f1f9[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Wed Oct 19 14:58:20 2022 +0530

    started part-2 of the calculation of the cause deleted life table (corresponding to STATA script's part-2). Calculated lx_del, nlx_del and tx_del columns (that are corresponding versions of the columns in the actual life table calculated before the cause deleted table).

[33mcommit a51383d528b971dfc976a0655baed433b8994ad8[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Mon Oct 17 12:37:14 2022 +0530

    added alpha_x, nqx_attrib columns to 'cleaned_joined_mort_rr_data_long_summary_cdlt' dataset and merged it with the 'actual_life_table', then added nrx and nqx_del columns. Reached end of part-1 of corresponding STATA script's cause deleted chunk of code.

[33mcommit 5351022200e0c0f42b4bbcba1a18a935e2bca24b[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Mon Oct 17 10:32:47 2022 +0530

    Final section of IER_2019 code file started: code for cause deleted life table calculation

[33mcommit 1f88efa47932365ecdd39418fb98653ccd2366cc[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Mon Oct 17 10:28:13 2022 +0530

    Calculated life expectancy at birth and save the 'cleaned_joined_mort_rr_data_long_summary' dataset in its current state into a new object named 'actual_life_table'

[33mcommit 4b13563f53e5c4ed9be83917a1806efa65ef5300[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Mon Oct 17 10:11:49 2022 +0530

    added the life expectancy column (ex)

[33mcommit 7f8b12dea54a5f56fe15a31acfd81c49e894e162[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Mon Oct 17 10:03:34 2022 +0530

    The nested for loop that calculates ntx, works!

[33mcommit 8de3b13fefc4a709c69384195a27c0d55ced124a[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Fri Oct 14 15:50:43 2022 +0530

    removing the old copy of the mortality file. All of he code in there is now incorporated in '3.calc_mortality_rates_and_lifetable_method', which in addition to mortality rates code, also includes the life table method code.

[33mcommit 38ff5aea9a46a8bcb5caa0589b291dcca9c8af2e[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Fri Oct 14 15:49:08 2022 +0530

    (a) everywhere 'age_interval' is used as a grouping/joining/arranging column, I have replaced it with 'age_interval_ll' because it is a numeric variable (more straightforward intution when it comes to arranging and sorting), whereas the 'age_interval' was a character column. (b) Added code to generate ndx, nlx and nfx columns of the actual life table.

[33mcommit ae39f8ec7541246cadd99c5213d662100fa6e4bb[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Oct 13 22:05:42 2022 +0530

    corrected a minor typo in the lx column comments

[33mcommit 2528080b6b9efa16787775769e24e060bc05d527[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Oct 13 22:04:34 2022 +0530

    added code to compute the lx (population of cohort still alive at the beginning of the age interval) column in the actual life table calculation

[33mcommit db957768550251bad76a6fc97f1d04b0a70b685e[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Oct 13 19:53:07 2022 +0530

    forgot to save file in the earlier step, saving now. Also, in the previous push, the name of the third file was changed to '3.calc_mortality_rates_and_life_table_method', because I am now computing the lifetable method within the third file.

[33mcommit 570410e5012f58a38c53c6ac0ed21b9a2111a92c[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Oct 13 19:51:10 2022 +0530

    Part 2 started: written 'actual life table' code till the point where we start computing lx, i.e. next step is to compute lx, which represents the population of cohort that is still alive at the beginning of a given age interval

[33mcommit 3a6ac296e649c035b7400eeca5c2079eba3a9805[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Wed Oct 12 19:00:44 2022 +0530

    status: R code written till the starting of the lifetable method calculation (corresponding to the point in the STATA script where Part-1 ends and file3 is saved. 395/542 lines transitioned to R)

[33mcommit da07ff8cb22439af927e7fbff630f5a5d91bccd2[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Tue Oct 11 20:19:23 2022 +0530

    Added the code for the 'rounding process', in which the global average pm2.5 is rounded up or down to the nearest pm_level buckets that are available in the pm_level column of 'cleaned_joined_mortality_rr_data_long' dataframe. This rounding process is implemented not by literal rounding, but rather by calculating distance of the pm_levels from the global_average_pm2.5 value and accordingly assigning the bucket based on the 'minimium distance', More notes in '3.calc_mortality_rates Rmd' file

[33mcommit 4190c17c0c65a74e35275262267dc4d69e3a001c[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Tue Oct 11 17:25:53 2022 +0530

    updating output, by resolving the bug that was leading to wierd errors. It was a namespace issue and some of plyr's functions were clashing with dplyr functions. For now, I have fixed this by not loading plyr and if at any point I need to use it, I use it by package:: notation.

[33mcommit 5f9538187bb7f0154d4cf15c502025b250685181[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Tue Oct 11 17:12:36 2022 +0530

    Written 3.calc_mortality_rates.Rmd file till the point where we merge mortality and relative risks data, reshape to long format and add in rr information for ages < 25. This corresponds to line 295 of Ken's IER 2019 script, which is stored as WIP_ier_stata_with_comments.do in this repo

[33mcommit 90b68bf01439b4715eb921adab4c4699dd5116c6[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Mon Oct 10 21:17:02 2022 +0530

    running all code to update output files and then push the latest output

[33mcommit 3b0a244a3a985d012647abb7f3d8c5ca165bf9ad[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Mon Oct 10 21:12:44 2022 +0530

    mortality rates cleaning file updated: (a) added encoding to cause column,(b) by adding a cause_id, added a age_gap and age_category columns. Coerced numeric columns into class numeric in both mortality and relative risks file.

[33mcommit 5436d5f3deb4769f14a01d3ebb2ca11d5d78ca4a[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Mon Oct 10 17:54:20 2022 +0530

    relative risk cleaning file: change final dataset from long to wide for easy merging. add a cause_id column to rr file for encoding cause names. add the ier2019 STATA WIP commented file which contains Ken's code

[33mcommit c55211887cc2c1834f0d63bdadeebf2bb8785a27[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Oct 6 18:25:24 2022 +0530

    starting the 'calc_mortality_rates' file, and written the initial merging code that joins the mortality rates data with the relative risks data

[33mcommit c993c90e1df7a6ffbbe3d1032fda536c2e4c2070[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Thu Oct 6 16:56:52 2022 +0530

    finalized cleaning of the relative risks and mortality rates raw datasets. Next step: Calculate mortality rates...

[33mcommit 5a57de5ccc1e17394c33b6f8e91de3cacbea37ae[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Tue Oct 4 14:37:42 2022 +0530

    finalizing cleaningMortalityRates script + added and started cleaning the relative risks file

[33mcommit e04b3cf390258623068df26c27c48aeb027706b6[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Wed Sep 28 18:51:59 2022 +0530

    added gbd_2019_mr_by_cause cleaning file with some initial cleaning steps

[33mcommit ba518c20b1a02753d27e0136d90d6906a3e62eb6[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Wed Sep 28 15:57:53 2022 +0530

    Adding a README file

[33mcommit 27485d0b1150b013e7b0d4c14db6f11345e436e9[m
Author: AarshBatra <aarshbatra.in@gmail.com>
Date:   Wed Sep 28 15:51:13 2022 +0530

    Initial Commit: Setting up file structure
