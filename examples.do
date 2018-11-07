********************************************************************************
*** Examples

clear
set more off
set seed 12345

*** Generating data ***
set obs 100
gen bdate = round(17000 + (100 + 3000*runiform()))
gen today = round(bdate + (100 + 3000*runiform()))

format bdate today %td



*** Compute date difference in years, months and days
datediff bdate today, format(years=years months = months days = days)

*** Compute date difference in years
datediff bdate today, format(years=years1)

*** Compute date difference in months
datediff bdate today, format(months = months1) 

*** Compute date difference in days
datediff bdate today, format(days=days1)

*** Compute date difference in years and months
datediff bdate today, format(years=years2 months = months2)

*** Compute date difference in months and days
datediff bdate today, format(months = months3 days = days3)

