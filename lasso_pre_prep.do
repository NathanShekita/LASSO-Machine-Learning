
use ${dd}\ed_episodes_cleaned.dta, clear

*Count of OON episodes
gen outin_count=1 if in_net_phys_ind==0 & in_net_fac_ind==1 
gen total_eps_fac=1 if in_net_fac_ind==1 
	

*Collapse to AHA year level
collapse(sum) outin_count total_eps_fac (first) emcare_entry_ind emcare_hosp teamhealth_entry_ind teamhealth_hosp hrr state county , by(aha year_start)
bysort aha year_start: gen inout_ratio=outin_count/total_eps_fac

destring(county), replace
	
tempfile temp1
save `temp1', replace

****************
*preparing data from income EOP project
	
use ${rd}\eop_xwalk\cw_cty00_cz.dta, clear
drop state_id stateabbrv

foreach v of varlist * {
	rename `v' eop_`v'
}
rename eop_county_id county
keep county eop_cz

tempfile temp2
save `temp2', replace

****************
*bring together

use `temp1', clear
merge m:1 county using `temp2'
	keep if _merge==3
	drop _merge


save ${dd}\lasso\aha_eop_cleaned.dta, replace
