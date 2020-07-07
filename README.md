# Machine Learning with a LASSO
An illustrative example of a LASSO applied to healthcare data with hundreds of independent variables. The figure shows conditional correlates of the variables selected from a LASSO that included data from the AHA, Equality of Opportunity Project, SK&A, and Health Leader Interstudy.
The outcome of interest (dependent variable) was hospital out-of-network billing prevalence. 

For more details please see the following paper: [Surprise! Out-of-Network Billing for Emergency Care in the United States](https://www.journals.uchicago.edu/doi/abs/10.1086/708819)

![Imgur](https://i.imgur.com/7dA0Lw0.png)


### Technical Overview
A lasso (least absolute shrinkage and selection operator) can be used for variable selection in a dataset with hundreds to thousands of possible indpendent variables. A relatively straightforward guide
to the mathematics behind the technique is summarized in a [post from Rob TibShirani](http://statweb.stanford.edu/~tibs/lasso/simple.html), who is credited with the methodology.

In short, the LASSO minimizes the sum of squared errors (as in OLS) subject to a constraint such that the sum of the absolute value of the coefficients is less than some parameter, t. This selects a subset of variables most correlated with the outcome of interest.

### Glmnet in R

[Glmnet is a package that fits a generalized linear model via penalized maximum likelihood](https://web.stanford.edu/~hastie/glmnet/glmnet_alpha.html).
The package allows the user to use cross-validation, a technique for prediction that assigns a *training* dataset (outcome is known) and a *testing* dataset (outcome is unkown). Cross-validation tests the model's prediction ability.
Because cross validation randomly selects a training and testing set, the best penalizing parameter is subject to slight variation on each iteration. Therefore, running a LASSO just once does not guarantee the same selection of variables.

To deal with this, the code runs the LASSO 100 times, takes the average of the selected penalizing parameters, and then fits the final model with that average. See the following code:

```R
for (i in 1:100) {
  fit <- cv.glmnet(x,y)
  sdlamb=data.frame(fit$lambda.1se)
  lambdas<-rbind(lambdas,sdlamb)
    }
  
lammat<-as.matrix(lambdas)
avgvalue=mean(lammat)
```

### Cleaning and preparing data

Prior to running the LASSO, Stata was used to clean the existing data.
Stata was used to create the conditional correlates plot seen above. 

Continuous variables are scaled so that they have a mean zero and SD of one.

```Stata
unab varlist: _all
unab exclude: emcare teamhealth year_start inout_ratio aha_mapp* aha_c_np aha_c_g eop_intersects_msa aha_techtotal_q* eop_gini99_q* hli_inshare_q*
local newlist: list varlist - exclude

*Standardize all other variables
foreach var of local newlist {
	egen `var'_temp=std(`var')
	drop `var'
	rename `var'_temp `var'
}
```

Measures for technology, insurer coverage, income, and gini coefficients were put into quintiles.

```Stata
local qlist hli_inshare aha_techtotal eop_gini99 eop_hhinc00

foreach f of local qlist {
	xtile pct=`f', n(5)
	tab pct, gen(`f'_q)
	drop `f'
	drop pct
}
```

### Coefficient Plot in Stata
The coefficient plot is then relatively simple using Stata's syntax. The local "reglist" denotes variables selected from the LASSO.

```Stata
reg inout_ratio `reglist' i.year_start
estimates store s1

graph set window fontface "Times New Roman"

*Plot coefficients from the regression
coefplot (s1, mcolor(`red') msymbol(circle) msize(small)), ///
mlabel format(%9.2g) mlabsize(vsmall) mlabcolor(`red') mlabposition(12) mlabgap(*.5) ///
headings(emcare="{bf:Physician Group Indicator}" aha_syshhi_15m="{bf:Market Characteristics}"  aha_c_np="{bf: Hospital Characteristics}" cen_countypop3="{bf:Local Area Characteristics}" ) ///
xlabel(-20 -15 -10 -5 0 5 10 15 20 25 30 35 40 45 50, labsize(small)) xtitle("Out-of-Network Rate (%)") ///
ciopts(recast(rcap) lwidth(thin) lcolor(`blue')) drop(_cons *year_start*) xline(0, lcolor(black) lstyle(makes_thin)) coeflabels(,labsize(vsmall)) 
```
