********************************************************************************
*** Computing difference between dates in units commonly used by humans

capture program drop _parse_format
program define _parse_format, sclass
	args myinput
	
	sreturn clear
	local strregex  "(years|months|days)[ ]*=[ ]*[a-zA-Z0-9_-]+"
	
	*** Parses pretty general syntax
	while regexm("`myinput'", "`strregex'") {
		local item `=regexs(0)'
		local myinput = trim(subinstr("`myinput'", "`item'", "", .))
		gettoken dateItem levs: item, parse("=")
		gettoken left levs: levs, parse("=")
		local dateItemVar = trim("`levs'")
		sreturn local `dateItem' `dateItemVar'
	}
	
end

capture program drop _daysInMonth
program define _daysInMonth
	args inDate outVar
	
	gen `outVar' = cond(inlist(month(`inDate'), 1,3,5,7,8,10,12), 31, ///
				   cond(inlist(month(`inDate'), 2) & mod(year(`inDate') , 4) == 0, 29, ///
				   cond(inlist(month(`inDate'), 2), 28, 30)))
end



capture program drop datediff
program define datediff
	syntax varlist(min=2 max=2), format(string asis) [replace]
	
	*** tokenize the varlist
	tokenize `varlist'
	local bdate `1'
	local today `2'
	
	*** parse the user-provided format
	_parse_format "`format'"
	
	foreach dateItem in "years" "months" "days" {
		local `dateItem' "`s(`dateItem')'"
		capture drop `"`dateItem'"'
	}
	
	if ("`replace'" ~= "") {
		capture drop `years' 
		capture drop `months' 
		capture drop `days'
	}
	
	*** check if variables are in td format
	if("`:format `bdate''" ~= "%td" | "`:format `today''" ~= "%td") {
		noi di in r "Variables in varlist should be in Stata date format. See help on datetime"
		exit 1000
	}
	
	*** If need the result in days
	if ("`years'" == "" & "`months'" == "") {
		*** difference in days
		gen `days' = `today' - `bdate'
	}
	else { // need results in years/months/days
	
	/*
		*** difference in months
		gen day1=day(bdate)
		gen month1=month(bdate)
		gen year1=year(bdate)

		gen day2=day(today)
		gen month2=month(today)
		gen year2=year(today)
	*/

		**** 
		* Assume that year2 > year1 --> may need to relax this
		
		tempvar dyear dmonth d1gtd2 cutoff  ///
			    dmon1 dmon2 dmonCoff tgtdt daysleft same_month resid 
				
		gen `dyear' = year(`today') - year(`bdate')
		gen `dmonth' = cond(`dyear' == 0, month(`today') - month(`bdate'), 12 - month(`bdate') + month(`today'))
		replace `dmonth' = (`dyear' - 1 )* 12 + `dmonth' if `dyear' > 1

		*** if day1 >= day2
		gen `d1gtd2' = (day(`bdate') >= day(`today'))
		replace `dmonth' = `dmonth' - 1 if `d1gtd2' == 1
		replace `dmonth' = `dmonth' if `d1gtd2' == 0

		*** move the time dmonths ahead
		cutoff `bdate', cd(`cutoff') mon(`dmonth')

		*** get the number of days per month
		_daysInMonth `bdate' `dmon1'
		_daysInMonth `today' `dmon2'
		_daysInMonth `cutoff' `dmonCoff'
		
		*** is day(cutoff) > day(today) ?
		gen `tgtdt' = (day(`cutoff') > day(`today'))
		gen `daysleft' = day(`today') - day(`cutoff') if `tgtdt' == 0
		replace `daysleft' = `dmonCoff' - day(`cutoff') + day(`today') if `tgtdt' == 1

		*** is month the same?
		gen `same_month' = (month(`today') == month(`cutoff'))
		replace `daysleft' = `dmonCoff' - day(`cutoff') + day(`today') if `same_month' == 0
		replace `dmonth' = `dmonth' + 1 if `dmonCoff' == `daysleft'
		replace `daysleft' = 0 if `dmonCoff' == `daysleft'

		*** if daysleft > dmon2
		gen `resid' = `daysleft' > `dmonCoff'
		replace `dmonth' = `dmonth' + 1 if `resid' ==1
		replace `daysleft' = `daysleft' - `dmonCoff' if `resid' ==1
		
		
		*** Reporting -->
		if ("`days'" == "") {
			tempvar addmonth cutoffN cutoffNextMonth dmonCOA ///
					daysInNextMonth surplusMonth

			*** Convert residual days to months
			*** Logic: 
			**** 1. Move cutoff by one day to start a new year
			**** 2. From this new date, move timeline by one month
			**** 3. Compute the number of days in the month
			**** 4. Compute the proportion of month feom days left
			
			gen `addmonth' = 1
			gen `cutoffN' = `cutoff' + 1
			cutoff `cutoffN', cd(`cutoffNextMonth') mon(`addmonth')
			_daysInMonth `cutoffN' `dmonCOA'

			*** is month(cutoffN) == month(`cutoffNextMonth')
			replace `same_month' = (month(`cutoffN') == month(`cutoffNextMonth'))
			gen `daysInNextMonth' = (`dmonCOA' - day(`cutoffN') +  day(`cutoffNextMonth') + 1) if `same_month' ==0
			replace `daysInNextMonth' = day(`cutoffNextMonth') - day(`cutoffN') + 1 if `same_month' == 1
			gen `surplusMonth' = `daysleft' / `daysInNextMonth'
			replace  `dmonth' =  `dmonth' + `surplusMonth'
		
			if ("`months'" == "") { // compute time in years
				noi di "Computing time in years"
				gen `years' = 0
				replace `years' = floor(`dmonth'/12)  if `dmonth' >=12
				replace `years' = `years' + mod(`dmonth', 12)/12
			}
			else if ("`years'" == "") { // compute time in months
				gen `months' = `dmonth'
			}
			else if ("`years'" ~= "" & "`months'" ~= "") {
				gen `years' = 0
				replace `years' = floor(`dmonth'/12)  if `dmonth' >=12
				gen `months' = mod(`dmonth', 12)
			}
		}
		else if ("`years'" == "") {  //compute time in months and days
			gen `months' = `dmonth'
			gen `days' = `daysleft'
		}
		else if ("`years'" ~= "" & "`months'" ~= "" & "`days'" ~= "") {
			*** compute everything in years, months and days
			gen `years' = 0
			replace `years' = floor(`dmonth'/12) if `dmonth' >=12
			gen `months' = mod(`dmonth', 12)
			gen `days' = `daysleft'
			
		}
		else {
			noi di in r "Option format not specified correctly"
			exit 1000
		}
	}

end