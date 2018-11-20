********************************************************************************
*** Examples

clear
set more off
set seed 12345

*** Generating data ***
set obs 1000
gen bdate = round(17000 + (100 + 3000*runiform())) if _n > 1
gen today = round(bdate + (100 + 3000*runiform())) if _n > 1
replace bdate = mdy(2, 29, 2012) if _n == 1
replace today = mdy(1, 26, 2015) if _n ==1
format bdate today %td


*** Define step forward
gen year = 3
gen month = 5
gen day = 15

*** Illustration of use and comparisons

*** Move bdate forward by the specified years, months and days, using age principle of calculation
dateForward bdate, gen(newvar) step(years = year months = month days = day)

*** Compute date difference in years, months and days, using age principle of calculation
dateDiff bdate newvar, gen(years=years months = months days = days) replace

*** Move bdate forward by the specified months, using age principle of calculation
dateForward bdate, gen(newvar) step(months = month) replace 

*** Compute date difference in months, using age principle of calculation
dateDiff bdate newvar, gen(months = months) replace


*** Additional examples

*** Move bdate forward by the specified years and days, using time principle of calculation
dateForward bdate, gen(newvar) step(years = year days = day) type(time) replace

*** Compute date difference in years, using time principle of calculation
dateDiff bdate newvar, gen(years=years1) type(time) replace
 
*** Compute date difference in months, using age principle of calculation
dateDiff bdate newvar, gen(months = months1) replace

*** Compute date difference in days, using age principle of calculation
dateDiff bdate newvar, gen(days=days1) replace

*** Compute date difference in years and months, using time principle of calculation
dateDiff bdate newvar, gen(years=years2 months = months2) type(time) replace

*** Compute date difference in months and days, using age principle of calculation
dateDiff bdate newvar, gen(months = months3 days = days3) replace
