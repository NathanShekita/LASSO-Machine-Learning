*Nathan Shekita

ed_paper2

******************************************
use ${dd}\lasso\aha_eop_cleaned.dta, clear


*Merge in all external data:
cd "${dd}\lasso"

*Equality of opportunity variables
merge m:1 eop_cz using eop_derived.dta
	keep if _merge==3
	drop _merge

*Market concentration measures
merge m:1 county using hli_hhis_derived.dta
	drop if _merge==2
	drop _merge

*SKA physicians
merge m:1 year_start hrr using ska_derived_yearly.dta
	drop if _merge==2
	drop _merge

*AHA hospital characteristics
merge 1:1 aha year_start using aha_derived_yearly.dta
	keep if _merge==3
	drop _merge

*Census bureau populations
merge m:1 county using population_county_derived.dta
	keep if _merge==3
	drop _merge

*Physician HHIs
merge m:1 county using baker_hhis.dta
	keep if _merge==3
	drop _merge

*Defining EmCare/Teamhealth hospitals
gen emcare=0
replace emcare=1 if emcare_hosp==1

gen teamhealth=0
replace teamhealth=1 if teamhealth_hosp==1	

*Not including entry hospitals	
drop if emcare_entry_ind==1
drop if teamhealth_entry_ind==1

*Cannot have missing variables
foreach var of varlist * {
	qui count if missing(`var')
	if r(N)/_N>0 di in red "`var'" 
	if r(N)/_N>0 drop `var'
}

*After dropping/merging, an AHA must appear in all 5 years
bysort aha: gen ycount=_N
keep if ycount==5

*Do not want in lasso
drop ycount aha pop_adj aha total_eps_fac outin_count hrr state raj_cz state county 

*dropping all variables that have no deviation
foreach var of varlist * {
	egen test=sd(`var')
	if test==0 di "`var'"
	if test==0 drop `var'
	drop test
}

*Variables not needed from AHA
drop aha_adc aha_adjadc aha_adjadm aha_adjpd aha_bdtot aha_ftothtf aha_ftrntf ///
aha_exptot aha_exptot aha_fttot aha_ftothtf aha_ipdtot aha_mcripd ///
aha_ptothtf aha_ptrntf aha_pttot aha_suropop aha_ftpht


*Variables not used from EOP
local droplist eop_n_ige_rank_8082	eop_e_rank_b_8082	eop_s_rank_8082	eop_prob_p1_k5	eop_e_rank_b_c1821	eop_s_c1821	 ///
	eop_e_rank_b_malefam	eop_s_malefam	eop_e_rank_b_indv_r_m	eop_s_indv_r_m	eop_e_rank_b_coli4 ///
	eop_s_coli4	eop_e_rank_b_1112	eop_s_1112	eop_e_rank_b_singlepar	eop_s_singlepar	///
	eop_e_rank_b_marriedpar	eop_s_marriedpar	eop_e_rank_b_8385	eop_s_rank_8385	eop_e_rank_b_8085 ///
	eop_s_rank_8085	eop_e_rank_b_w80	eop_s_w80	eop_n_ige_rank_8085	eop_prob_p1_k1	eop_prob_p1_k2 ///
	eop_prob_p1_k3	eop_prob_p1_k4	eop_prob_p1_k5	eop_prob_p2_k1	eop_prob_p2_k2	eop_prob_p2_k3 ///
	eop_prob_p2_k4	eop_prob_p2_k5	eop_prob_p3_k1	eop_prob_p3_k2	eop_prob_p3_k3	eop_prob_p3_k4 ///
	eop_prob_p3_k5	eop_prob_p4_k1	eop_prob_p4_k2	eop_prob_p4_k3	eop_prob_p4_k4	eop_prob_p4_k5 ///
	eop_prob_p5_k1	eop_prob_p5_k2	eop_prob_p5_k3	eop_prob_p5_k4	eop_prob_p5_k5	eop_frac_par_1 ///
	eop_frac_par_2	eop_frac_par_3	eop_frac_par_4	eop_frac_par_5	eop_frac_kid_1	eop_frac_kid_2 ///
	eop_frac_kid_3	eop_frac_kid_4	eop_frac_kid_5	eop_n_ige_rank_8082	eop_kid_fam_inc_mean ///
	eop_kid_fam_inc_p50	eop_kid_fam_inc_p10	eop_kid_fam_inc_p25	eop_kid_fam_inc_p75	eop_kid_fam_inc_p90 ///
	eop_kid_fam_inc_p99	eop_par_fam_inc_mean eop_par_fam_inc_p50	eop_par_fam_inc_p10	eop_par_fam_inc_p25 ///
	eop_cs00_seg_inc_pov25 eop_cs00_seg_inc_aff75 eop_par_fam_inc_p75	eop_par_fam_inc_p90	eop_par_fam_inc_p99 ///
	eop_pop2000 eop_cs_born_foreign eop_tax_st_diff_top20 eop_eitc_exposure

	*No longer using
	drop ska_phys_count ska_ed_phys_count hli_hhi_hcci hli_icount_all
	
foreach f of local droplist {
	capture drop `f'
}	




*fixing AHA indicators
foreach var of varlist aha_mapp* {
	replace `var'=0 if `var'==2
}


*Take the square and cube to be selected in the lasso
local sparse aha_vtot aha_fte cen_countypop
foreach f of local sparse {
	gen `f'2=`f'^2
	gen `f'3=`f'^3
}

order inout_ratio

*Technology, insurer coverage, income, and gini put into quintiles
local qlist hli_inshare aha_techtotal eop_gini99 eop_hhinc00

foreach f of local qlist {
	xtile pct=`f', n(5)
	tab pct, gen(`f'_q)
	drop `f'
	drop pct
}

preserve

drop year_start

*Version for use in R, running glmnet
saveold C:\Documents\R_work\lasso_regs.dta, replace version(12)

restore

*Version for use in Stata
save ${dd}\lasso\lasso_regs.dta, replace


****************************************************
