********************************************************************************
*** Computing date shifts and difference between dates in units commonly 
***                           used by humans


*** Move a date forward or backwards
capture program drop dateShift
program define dateShift, sclass

	syntax varlist(max=1) [if] [in], GENerate(name) step(string asis) ///
									[type(string asis) replace INConsistent(name)]
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
				exit 498
			}
		}
		_parse_format "`step'"
		
		*** collect variable names
		foreach dateItem in "years" "months" "days" {
			local `dateItem' "`s(`dateItem')'"
		}
		
		*** Drop variables if replace is specified
		if ("`replace'" ~= "") {
			capture drop `generate'
			capture drop `inconsistent'
		}
		
		*** Generate variables for any missing step sub-arguments
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

		*** Check values of shift variables
		foreach var of varlist `years' `months' `days' {
			sum `var'
			local `var'Mean = `r(mean)'
		}
		
		*** If no shift is requested
		if ("`yearsMean'" == "0" & "`monthsMean'" == "0" & "`daysMean'" == "0") {
			gen `generate' = `bdate'		
		}
		else {	
			
			tempvar sign day month adjMonths year nbdate month_excess day_excess nday_excess daysInMonth ym bdDaysInMonth
			
			*** Check consistency of shift requests
			mata: consistencyCheck("`days' `months' `years'", "`touse'")
			
			sum `touse'
			if "`compliers'" ~= "`r(sum)'" {
				noi di in r "Inconsistent shift request." _n ///
				"Please, ensure that within an observation year, month and day are all non-negative or non-positive"
				exit 498
			}
			
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

			*** Handle day overflow
			_daysInMonth `ym' `daysInMonth'	
			
			*** Generating date and making a few adjustments 
			if ("`type'" == "age") {
			
				***********************
				*** Moving date forward
			
				*** February and first of the month adjustment
				gen `generate' = cond(`sign' == 1, ///
								 cond(month(`ym') == 2 & (day(`bdate') > `daysInMonth'), ///
								  `ym' + `daysInMonth' - 1 + `days', ///
								  `ym' + day(`bdate') + `days' - 2), ///
								 `ym') if `touse'
				
				*************************				 
				*** Moving date backwards
					
				*** Adjustments for overflow arising from months with 30 days; February is excluded
				replace `generate' = cond(`daysInMonth' < day(`bdate') + 1 & inlist(`month', 4, 6, 9, 11),  ///
									  `ym' + day(`bdate') -1 + `days' , ///
									   cond(`month' == 2, `ym', `ym' + day(`bdate') + `days')) if `sign' == -1 & `touse'
						
				*** Adjustments for February
				replace `generate' = cond(`daysInMonth' < day(`bdate') + 1 , ///
										  `ym' + `daysInMonth' - 1 + `days', ///
										  `ym' + day(`bdate') + `days') if `month' == 2 & `sign' == -1 & `touse'
			}
			else {
			
				***********************
				*** Moving date forward
				
				*** February and first of month adjustment
				gen `generate' = cond(`sign' == 1, ///
								 cond(month(`ym') == 2 & (day(`bdate') > `daysInMonth'), ///
								  `ym' + `daysInMonth' + `days', ///
								  `ym' + day(`bdate') + `days' - 1), ///
								 `ym') if `touse'
			
						
				*************************				 
				*** Moving date backwards
				
				*** Adjustments for overflow arising from months with 30 days; February is excluded
				replace `generate' = cond(`daysInMonth' < day(`bdate') & inlist(`month', 4, 6, 9, 11),  ///
									  `ym' + day(`bdate') - 2 + `days', ///
									   cond(`month' ==2, `ym', `ym' + day(`bdate') - 1 + `days')) if `sign' == -1 & `touse'
							
				*** Adjustments for February
				replace `generate' = cond(`daysInMonth' < day(`bdate'), ///
										  `ym' + `daysInMonth' - 1 + `days', ///
										  `ym' + day(`bdate') - 1 + `days') if `month' == 2 & `sign' == -1 & `touse'
			}
		}
		format `generate' %td
		
		if ("`inconsistent'" ~= "") {
		
			tempvar checkDate years1 months1 days1
			
			foreach tp in "years" "months" "days" {
				gen ``tp'1' = abs(``tp'')
			}
			dateShift `generate', gen(`checkDate') step(years= `years1' months = `months1' days = `days1') type(`type')
			gen `inconsistent' = (`bdate' ~= `checkDate')
		}
	}
end


*** Compute difference between dates
capture program drop dateDiff
program define dateDiff, sclass
	syntax varlist(min=2 max=2) [if] [in], GENerate(string asis) [Type(string asis) replace]

	qui {	
		*** tokenize the varlist
		tokenize `varlist'
		local bdate `1'
		local today `2'
		
		marksample touse
		
		*** parse the user-provided format
		_parse_format "`generate'"
		
		foreach dateItem in "years" "months" "days" {
			local `dateItem' "`s(`dateItem')'"
		}
		
		*** Check type
		if "`type'" == "" {
			local type "age"
		}
		else {
			if (!inlist("`type'", "age", "time")) {
				noi di in r "Option type specified incorrectly."
				exit 498
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
			exit 498
		}
		
		if ("`years'" == "" & "`months'" == "") {
			*** difference in days
			gen `days' = `today' - `bdate' + 1 if `touse'
		}
		else {
			
			if ("`years'" == "") {
				tempvar vyears
			}
			if ("`months'" == "") {
				tempvar vmonths
			}
			if ("`days'" == "") {
				tempvar vdays
			}
					
			tempvar vyears vmonths vdays shiftedDate daysInToday
			
			*** Compute diff in months
			gen `vyears' = year(`today') - year(`bdate') if `touse'
			
			gen `vmonths' = cond(`vyears' == 0, ///
								 month(`today') - month(`bdate'), ///
								 12 - month(`bdate') + month(`today')) if `touse'
	
			if ("`type'" == "age") {
				replace `vmonths' = `vmonths' - 1 if day(`bdate') - 1 > day(`today')
		
				*** Adjustment for same month
				_daysInMonth `today' `daysInToday' 
				replace `vmonths' = `vmonths' + 1 if `vmonths' == 0 & ///
									day(`bdate') == 1 & day(`today') == `daysInToday'				
			}		
			else {
				replace `vmonths' = `vmonths' - 1 if day(`bdate') > day(`today')
				
			}

			replace `vmonths' = (`vyears' - 1 )* 12 + `vmonths' if `vyears' > 1 
			
			*** Move bdate forward by the amount of months
			dateShift `bdate' if `touse', gen(`shiftedDate') step(months = `vmonths') type(`type')
			
			*** Generate days
			gen `vdays' = `today' - `shiftedDate' if `touse'
				
			*** Update year
			replace `vyears' = floor(`vmonths'/12) if `touse'
			replace `vmonths' = mod(`vmonths',12) if `touse'			
			
			
			******************************
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
				
				tempvar oneMonth nextMonth daysNextMonth
				
				gen `oneMonth' = 1 if `touse'
				
				if ("`type'" == "age") {
					replace `shiftedDate' = `shiftedDate' + 1
				}
				
				dateShift `shiftedDate' if `touse', gen(`nextMonth') step(months = `oneMonth') type(`type')
				gen `daysNextMonth' = `nextMonth' - `shiftedDate' if `touse'  // month in days
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
				exit 498
			}
		}
	}
end


*** Parser of format input
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


*** Report the max number of days of the month
capture program drop _daysInMonth
program define _daysInMonth
	args inDate outVar
	
	gen `outVar' = cond(inlist(month(`inDate'), 1,3,5,7,8,10,12), 31, ///
				   cond(inlist(month(`inDate'), 2) & mod(year(`inDate') , 4) == 0, 29, ///
				   cond(inlist(month(`inDate'), 2), 28, 30)))
end


*** Check consistency of requested shifts
cap mata : mata drop consistencyCheck()
mata:
void function consistencyCheck(string scalar vars, string scalar touse) {
	
	real matrix mydata

	st_view(mydata, ., (vars), touse)
	nPos  = colsum(rowsum(mydata :>=0) :== 3)
	nNeg  = colsum(rowsum(mydata :<=0) :== 3)
	nZero = colsum(rowsum(mydata :==0) :== 3)
	n = nPos + nNeg - nZero

	st_local("compliers", strofreal(n))
}
end
