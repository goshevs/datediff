********************************************************************************
***** Testing cutoff
********************************************************************************


clear
set more off


set obs 100
gen bdate = round(17000 + (100 + 3000*runiform()))
gen today = round(bdate + (100 + 3000*runiform()))

format bdate today %td

*** difference in days
gen days_diff = today - bdate

*** difference in months
gen day1=day(bdate)
gen month1=month(bdate)
gen year1=year(bdate)

gen day2=day(today)
gen month2=month(today)
gen year2=year(today)


**** 
* Assume that year2 > year1

gen dyear = year2 - year1
gen dmonth = cond(dyear == 0, month2 - month1, 12 - month1 + month2)
replace dmonth = (dyear - 1 )* 12 + dmonth if dyear > 1

*** if day1 >= day2
gen d1gtd2 = (day1 >= day2)
replace dmonth = dmonth - 1 if d1gtd2 == 1
replace dmonth = dmonth if d1gtd2 == 0

*** move the time to dmonths ahead
cutoff bdate, cd(test1) mon(dmonth)

*** get the number of days per month
gen dmon1 = cond(inlist(month1, 1,3,5,7,8,10,12), 31, ///
				cond(inlist(month1, 2) & mod(year1, 4) == 0, 29, ///
					cond(inlist(month1, 2), 28, 30)))
gen dmon2 = cond(inlist(month(test1), 1,3,5,7,8,10,12), 31, ///
				cond(inlist(month(test1), 2) & mod(year(test1), 4) == 0, 29, ///
					cond(inlist(month(test1), 2), 28, 30)))


*** is day(test1) > day(today) ?
gen tgtdt = (day(test1) > day(today))
gen daysleft = day2 - day(test1) if tgtdt == 0
replace daysleft = dmon2 - day(test1) + day2 if tgtdt == 1

*** is month the same?
gen same_month = (month2 == month(test1))
replace daysleft = dmon2 - day(test1) + day2 if same_month == 0
replace dmonth = dmonth + 1 if dmon2 == daysleft
replace daysleft = 0 if dmon2 == daysleft

*** if daysleft > dmon2
gen test2 = daysleft > dmon2
replace dmonth = dmonth + 1 if test2 ==1
replace daysleft = daysleft - dmon2 if  test2 ==1

*** age
gen year = 0
replace year = floor(dmonth/12) if dmonth >=12
gen month = mod(dmonth, 12)
gen day = daysleft


		

 