********************************************************************************
*** Computing difference between dates in units commonly used by humans


*** Move a date forward or backwards
capture program drop dateShift
program define dateShift, sclass

	syntax varlist(max=1) [if] [in], GENerate(name) step(string asis) ///
									[type(string asis) replace]
	qui{
		tokenize `varlist'
		args bdate
		
		marksample touse

		if "`type'" == "" {
			local type "age"
		}
		else {
			if (!inlist("`type'", "age", "time")) {
				noi di in r "Option type specified incorrectly."
				exit 1000
			}
		}
		_parse_format "`step'"
		
		*** collect variable names
		foreach dateItem in "years" "months" "days" {
			local `dateItem' "`s(`dateItem')'"
		}
		
		*noi di "`years'"
		*noi di "`months'"
		*noi di "`days'"
		
		if ("`replace'" ~= "") {
			capture drop `generate'
		}
		
		if ("`years'" == "") {
			tempvar years
			gen `years' = 0
		}
		if ("`days'" == "") {
			tempvar days
			gen `days' = 0
		}
		if ("`months'" == "") {
			tempvar months
			gen `months' = 0
		}
		
		tempvar sign day month adjMonths year nbdate month_excess day_excess nday_excess daysInMonth ym bdDaysInMonth
		
		*** Define direction of shift
		gen `sign' = 1
		replace `sign' = -1 if sign(`days') == -1 | sign(`months') == -1 | sign(`years') == -1
				
		*** Move months first
		
		*** Take care of months that are greater than 12
		gen `year' = floor(`months'/12)
		gen `adjMonths' = mod(`months',12)
			
		*** Months greater than 12
		gen `month_excess' = (month(`bdate') + `adjMonths' > 12)
		
		*** Move months
		gen `month' = cond(`month_excess' == 0, ///
							month(`bdate') + `adjMonths', ///
							mod(month(`bdate') + `adjMonths' ,12))
		replace `year' = cond(`month_excess' == 0, ///
						   `year' + year(`bdate'), ///
						   `year' + year(`bdate') + floor((month(`bdate') + `adjMonths' )/12))

		*** Move years
		replace `year' = `year' + `years'
	
		
		gen `ym' = mdy(`month', 1, `year') 		// this is needed for the _daysInMonth function
		
		if ("`type'" == "age") {
			replace `ym' = cond(`sign' == -1, `ym' + day(`bdate'), `ym') 
		}
		else {
			replace `ym' = cond(`sign' == -1, `ym' + day(`bdate') - 1, `ym')
		}
			
		*** Handle day overflow
		_daysInMonth `ym' `daysInMonth'	
		
		*** Move days
		if ("`type'" == "age") {
			*** February and first of month adjustment
			gen `generate' = cond(`sign' == 1, ///
							 cond(month(`ym') == 2 & (day(`bdate') > `daysInMonth'), ///
							  `ym' + `daysInMonth' - 1 + `days', ///
							  `ym' + day(`bdate') + `days' - 2), ///
							 cond(month(`ym') == 2 & (day(`bdate') > `daysInMonth'), ///
							  `ym' + `daysInMonth' + `days', ///
							  `ym' + `days')) if `touse'
		}
		else {
			*** February and first of month adjustment
			gen `generate' = cond(`sign' == 1, ///
							 cond(month(`ym') == 2 & (day(`bdate') > `daysInMonth'), ///
							  `ym' + `daysInMonth' + `days', ///
							  `ym' + day(`bdate') + `days' - 1), ///
							  cond(month(`ym') == 2 & (day(`bdate') > `daysInMonth'), ///
							  `ym' + `daysInMonth' + `days' + 1, ///
							  `ym' + `days')) if `touse'
		}
		format `generate' %td
	}
end


*** Compute difference between dates
capture program drop dateDiff
program define dateDiff, sclass
	syntax varlist(min=2 max=2), GENerate(string asis) [Type(string asis) replace]

	qui {	
		*** tokenize the varlist
		tokenize `varlist'
		local bdate `1'
		local today `2'
		
		*** parse the user-provided format
		_parse_format "`generate'"
		* sreturn list
		
		foreach dateItem in "years" "months" "days" {
			local `dateItem' "`s(`dateItem')'"
		}
		
		* noi di "`years'"
		* noi di "`months'"
		* noi di "`days'"
		
		
		if "`type'" == "" {
			local type "age"
		}
		else {
			if (!inlist("`type'", "age", "time")) {
				noi di in r "Option type specified incorrectly."
				exit 1000
			}
		}
		
		if ("`replace'" ~= "") {
			capture drop `years' 
			capture drop `months' 
			capture drop `days'
		}
		
		*** check if variables are in td format
		if("`:format `bdate''" ~= "%td" | "`:format `today''" ~= "%td") {
			noi di in r "Variables in varlist should be in Stata date format (%td). See help on datetime"
			exit 1000
		}
		
		if ("`years'" == "" & "`months'" == "") {
			*** difference in days
			gen `days' = `today' - `bdate' + 1
		}
		else {
			* noi di "Year/month/day"
			
			if ("`years'" == "") {
				tempvar vyears
			}
			if ("`months'" == "") {
				tempvar vmonths
			}
			if ("`days'" == "") {
				tempvar vdays
			}
					
			tempvar vyears vmonths vdays diffMonth shiftedDate  ///
						dmon1 dmon2 dmon3 same_month resid 
			
			*** Compute diff in months
			gen `vyears' = year(`today') - year(`bdate')
			
			gen `vmonths' = cond(`vyears' == 0, month(`today') - month(`bdate'), 12 - month(`bdate') + month(`today'))
			replace `vmonths' = `vmonths' - 1 if day(`bdate') > day(`today')
			replace `vmonths' = (`vyears' - 1 )* 12 + `vmonths' if `vyears' > 1
			
			*** Move bdate forward by the amount of months
			dateShift `bdate', gen(`shiftedDate') step(months = `vmonths') type(`type')
					
			*** Compute difference in days
			_daysInMonth `bdate' `dmon1'  // number of days in month(bdate)
			
			gen `vdays' = `today' - `shiftedDate'
				
			*** fix year
			replace `vyears' = floor(`vmonths'/12)
			replace `vmonths' = mod(`vmonths',12)				
			
			
			*** Reporting
			if ("`years'" ~= "" & "`months'" ~= "" & "`days'" ~= "")  {
				gen `years'  = `vyears'
				gen `months' = `vmonths'
				gen `days'   = `vdays'
			}
			else if ("`days'" == "") {
				*** Convert residual days to months and years in months
				*** Logic: 
				**** 1. Move shiftedDay by one day to start a new year (if type = age)
				**** 2. From this new date, move timeline by one month 
				**** 3. Compute difference in number of days between new date and shiftedDay
				**** 4. Compute the proportion of month and add years
				
				tempvar oneMonth nextMonth dmon4 daysNextMonth
				
				gen `oneMonth' = 1
				
				if ("`type'" == "age") {
					replace `shiftedDate' = `shiftedDate' + 1
				}
				
				dateShift `shiftedDate', gen(`nextMonth') step(months = `oneMonth') type(`type')
				gen `daysNextMonth' = `nextMonth' - `shiftedDate'   // month in days
				replace `vmonths' = `vmonths' + `vdays'/`daysNextMonth'
				
				if ("`years'" == "") {  // compute time in months
					replace `vmonths' = `vmonths' + `vyears' * 12
					gen `months' = `vmonths'
				}
				else if ("`months'" == "") {  // compute time in years
					replace `vyears' = `vyears' + `vmonths'/12
					gen `years' = `vyears'
				}
				else if ("`years'" ~= "" & "`months'" ~= "") {
					gen `years' = `vyears'
					gen `months' = `vmonths'
					
				}
			}	
			else if ("`years'" == "") {
				replace `vmonths' = `vmonths' + `vyears' * 12
				
				gen `months' = `vmonths' 
				gen `days'   = `vdays'
			}
			else {
				noi di in r "Option format specified incorrectly"
				exit 1000
			}
			
			* gen shiftedDate = `shiftedDate'
			* gen nextMonth = `nextMonth'
			* format shiftedDate %td	
		}
	}
end


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
