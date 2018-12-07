********************************************************************************
*** Examples

clear
snapshot erase 1

set more off
set seed 12345

*** Generating data ***
set obs 10000
gen bdate = round(17000 + (100 + 3000*runiform())) if _n > 1
gen today = round(bdate + (100 + 3000*runiform())) if _n > 1
replace bdate = mdy(2, 29, 2012) if _n == 1
replace today = mdy(1, 26, 2015) if _n ==1
format bdate today %td

snapshot save


********************************************************************************
*** MOVING DATES
********************************************************************************


************************
*** Define a random step forward for every date

gen year = round(5*runiform())
gen month = round(15*runiform())
gen day = round(31*runiform())

/* Alternatively, can define a common step for all dates
gen year = 2
gen month = 9
gen day = 6
*/

*** Move bdate forward by the specified years, months and days, using age principle of calculation
dateShift bdate, gen(newdate) step(years = year months = month days = day)

*** Move bdate forward by the specified months, using age principle of calculation
dateShift bdate, gen(newdate) step(months = month) replace 

*** Move bdate forward by the specified years and days, using time principle of calculation
dateShift bdate, gen(newdate) step(years = year days = day) type(time) replace

snapshot restore 1


**************************
*** Define a random step backwards for every date

gen year = -round(5*runiform())
gen month = -round(15*runiform())
gen day = -round(31*runiform())

*** Move bdate backwards by the specified years, months and days, using age principle of calculation
dateShift bdate, gen(newdate) step(years = year months = month days = day) replace

*** Move bdate backwards by the specified months, using age principle of calculation
dateShift bdate, gen(newdate) step(months = month) replace 

*** Move bdate backwards by the specified years and days, using time principle of calculation
dateShift bdate, gen(newdate) step(years = year days = day) type(time) replace


snapshot restore 1


********************************************************************************
*** DIFFERENCES BETWEEN DATES
********************************************************************************


*** Setup: Define a random step forward and a shift date
gen year = round(5*runiform())
gen month = round(15*runiform())
gen day = round(31*runiform())
dateShift bdate, gen(newdate) step(years = year months = month days = day) replace

*** Compute date difference in years, months and days, using age principle of calculation
dateDiff bdate newdate, gen(years=years1 months = months1 days = days1) replace

*** Compute date difference in months, using age principle of calculation
dateDiff bdate newdate, gen(months = months1) replace

*** Compute date difference in years, using time principle of calculation
dateDiff bdate newdate, gen(years=years2) type(time) replace
 
*** Compute date difference in days, using age principle of calculation
dateDiff bdate newdate, gen(days=days1) replace

*** Compute date difference in years and months, using time principle of calculation
dateDiff bdate newdate, gen(years=years3 months = months3) type(time) replace

*** Compute date difference in months and days, using age principle of calculation
dateDiff bdate newdate, gen(months = months4 days = days4) replace
