********************************************************************************
*** Examples

clear
set more off
set seed 12345

*** Generating data ***
set obs 1000
gen bdate = round(17000 + (100 + 3000*runiform())) if _n > 1
gen today = round(bdate + (100 + 3000*runiform())) if _n > 1
replace bdate = mdy(2, 26, 2012) if _n == 1
replace today = mdy(1, 26, 2015) if _n ==1
format bdate today %td

gen year = 4
gen month = 8
gen day = 30



*** cutoff
dateForward bdate, gen(newvar) step(years = year months = month days = day) type(age)
*dateForward bdate, gen(newvar) step(days = day) type(age) replace
* br if month(bdate) == 1 & inlist(day(bdate),1)
* br if month(bdate) == 1 & inlist(day(bdate),25, 26, 27, 28, 29, 30, 31)


***
dateDiff bdate newvar, format(years=myyears months=mymonths days=mydays) type(age)
* dateDiff bdate newvar, format(days=mydays) type(age) replace
* br if mydays ~= 4

* br if month(bdate) == 1 & inlist(day(bdate),1)
* br if month(bdate) == 1 & inlist(day(bdate),25, 26, 27, 28, 29, 30, 31)
exit









*** Compute date difference in years, months and days
dateDiff bdate today, format(years=years months = months days = days)

*** Compute date difference in years
dateDiff bdate today, format(years=years1)

*** Compute date difference in months
dateDiff bdate today, format(months = months1) 

*** Compute date difference in days
dateDiff bdate today, format(days=days1)

*** Compute date difference in years and months
dateDiff bdate today, format(years=years2 months = months2)

*** Compute date difference in months and days
dateDiff bdate today, format(months = months3 days = days3)

