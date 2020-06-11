
estimates clear

local blue `""33 102 172""'
local red `""178 24 43""'

use ${dd}\lasso\lasso_regs.dta, clear

*OON rate
replace inout_ratio=inout_ratio*100

*Indicators that we do not want standardized
unab varlist: _all
unab exclude: emcare teamhealth year_start inout_ratio aha_mapp* aha_c_np aha_c_g eop_intersects_msa aha_techtotal_q* eop_gini99_q* hli_inshare_q*
local newlist: list varlist - exclude

*Standardize all other variables
foreach var of local newlist {
	egen `var'_temp=std(`var')
	drop `var'
	rename `var'_temp `var'
}

*Labels
do ${sc}\label_vars_short.do
cap label var emcare "EmCare"
cap label var teamhealth "TeamHealth"

*Variables chosen from Lasso + market characteristics, to be used in regressions
local reglist emcare teamhealth aha_syshhi_15m hli_hhi_all ska_ed_phys_per_capita baker_hhi ska_phys_per_capita aha_c_np aha_c_g aha_mapp3 aha_mapp8 aha_mapp5 aha_fte aha_prop_care aha_techtotal_q1 aha_techtotal_q5 cen_countypop3 eop_cs_fam_wkidsinglemom eop_cs_married eop_gini99_q1
	
reg inout_ratio `reglist' i.year_start
estimates store s1

graph set window fontface "Times New Roman"

*Plot coefficients from the regression
coefplot (s1, mcolor(`red') msymbol(circle) msize(small)), ///
mlabel format(%9.2g) mlabsize(vsmall) mlabcolor(`red') mlabposition(12) mlabgap(*.5) ///
headings(emcare="{bf:Physician Group Indicator}" aha_syshhi_15m="{bf:Market Characteristics}"  aha_c_np="{bf: Hospital Characteristics}" cen_countypop3="{bf:Local Area Characteristics}" ) ///
xlabel(-20 -15 -10 -5 0 5 10 15 20 25 30 35 40 45 50, labsize(small)) xtitle("Out-of-Network Rate (%)") ///
ciopts(recast(rcap) lwidth(thin) lcolor(`blue')) drop(_cons *year_start*) xline(0, lcolor(black) lstyle(makes_thin)) coeflabels(,labsize(vsmall)) 

graph export ${o}/final_figures/lasso_mstructure.png, width(1500) height(1000) as(png) replace



