********************************************************************************
**** Compute cutoff time
***
** Simo Goshev
** v.0.05
**
**

*** 

capture program drop dateForward
program define dateForward, sclass

	syntax varlist(max=1) [if] [in], gen(name) step(string asis) ///
									[type(string asis) replace]

	tokenize `varlist'
	args bdate
	
	marksample touse

	_parse_format "`step'"
	
	*** collect variable names
	foreach dateItem in "years" "months" "days" {
		local `dateItem' "`s(`dateItem')'"
	}
	
	*noi di "`years'"
	*noi di "`months'"
	*noi di "`days'"
	
	if ("`replace'" ~= "") {
		capture drop `gen'
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
	
	tempvar day month adjMonths year nbdate month_excess day_excess nday_excess daysInMonth ym
	
	*** Move months first
	
	*** Take care of months that are greater than 12
	gen `year' = floor(`months'/12)
	gen `adjMonths' = mod(`months',12)
		
	*** Months greater than 12
	
	gen `month_excess' = (month(`bdate') + `adjMonths' > 12)
	
	*** Move forward months
	gen `month' = cond(`month_excess' == 0, ///
						month(`bdate') + `adjMonths', ///
						mod(month(`bdate') + `adjMonths' ,12))
	replace `year' = cond(`month_excess' == 0, ///
					   `year' + year(`bdate'), ///
					   `year' + year(`bdate') + floor((month(`bdate') + `adjMonths' )/12))

	*** Move forward years
	replace `year' = `year' + `years'
	
	gen `ym' = mdy(`month', 1, `year')  // this is needed for the _daysInMonth function
	
	*** Handle day overflow
	_daysInMonth `ym' `daysInMonth'	
						   
	*** Move forward days
	if ("`type'" == "age") {

		*** February and first of month adjustment
		gen `gen' = cond(month(`ym') == 2 & (day(`bdate') > `daysInMonth'), ///
						 `ym' + `daysInMonth' - 1 + `days', ///
						 `ym' + day(`bdate') + `days' - 2)					
	}
	else {
		*** Case in which type is not age -- TEST THIS!
		*** February and first of month adjustment
		gen `gen' = cond(month(`ym') == 2 & (day(`bdate') > `daysInMonth'), ///
						 `ym' + `daysInMonth' + `days', ///
						 `ym' + day(`bdate') + `days' - 1)	
	}
	
	
	/*
	gen months = `month'
	gen months_excess = `month_excess'
	gen adjmonths = `adjMonths'
	
	gen daysInMonth = `daysInMonth'
	gen ym = `ym'
	gen days_excess = `day_excess'
	format ym %td

	* gen `gen' = `ym'
	*/
	
	format `gen' %td
end

exit

	
	
	
tempvar day month year y_d m_d over12 cond1 dayn flag1 flag2 excess
	
	gen `day'=day(`bdate') if `touse' 
	gen `month'=month(`bdate') if `touse' 
	gen `year'=year(`bdate') if `touse' 
		
	if `mon'==0 {
		gen `cdate'=`bdate' if `touse'
	}
	else if `mon'>0 { 
	
		gen `y_d'=floor(`mon'/12) if `touse' 
		gen `m_d'=mod(`mon',12) if `touse' 
		gen `over12'=(`month'+`m_d') if `touse'       // --> this could be over 12! 
		
		gen `dayn'=`day'-1 if `touse'
		replace `over12'=`over12'-1 if `dayn'==0 & `touse'
		gen `excess'=mod(`over12',12) if `touse'   

		replace `y_d'=`y_d'+1 if `over12'>12 & `touse'
		gen `cond1'=mod(`year'+`y_d',4) if `touse'
					
		replace `over12'=`over12' -1 if `dayn'==0 & `touse'
		replace `excess'=12 if `excess'==0 & `touse'
		replace `dayn'=31 if `dayn'==0 & inlist(`excess',1,3,5,7,8,10,12) & `touse'
		replace `dayn'=30 if `dayn'==0 & ~inlist(`excess',1,3,5,7,8,10,12) & `touse'
		replace `dayn'=29 if `dayn'==0 & inlist(`over12',2) & `cond1'==0 & `touse'
		replace `dayn'=28 if `dayn'==0 & inlist(`over12',2) & `cond1'~=0 & `touse'
		replace `dayn'=30 if `dayn'>=31 & ~inlist(`excess',1,3,5,7,8,10,12) & `touse'
					
		replace `dayn'=29 if `excess'==2 & `dayn'>28 & `cond1'==0 & `touse'
		replace `dayn'=28 if `excess'==2 & `dayn'>28 & `cond1'~=0 & `touse'

		replace `cdate'=mdy(`excess',`dayn',`year'+`y_d') if `touse'
		replace `cdate'=mdy(`excess',`dayn',`year') if `over12'<0 & `touse'
	
	}
			
	else {

		gen `y_d'=floor(`mon'/12) if `touse' 
		gen `m_d'=mod(`mon',12) if `touse' 
		gen `over12'=(`month'+`m_d') if `touse'   // --> this could be over 12!
		gen `excess'=mod(`over12',12)  if `touse'
		
		gen `dayn'=`day'+1 if `touse'
		gen `flag1'=1 if (`dayn'>31 & inlist(`excess',0,1,3,5,7,8,10,12)  & `touse') | (`dayn'>30 & ~inlist(`excess',0,1,3,5,7,8,10,12)  & `touse')
		replace `over12'=`over12'+1 if `flag1'==1 & `excess'~=0 & `over12'~=12 & `touse'
	
		replace `year'=`year'+1 if `over12'>12 & `touse'		
		replace `over12'=mod(`over12', 12) if `over12'>12 & `touse'
		
		replace `dayn'=1 if `flag1'==1 & `touse'		

		
		*** Fixing leap years *** 	
		
		gen `cond1'=mod(`year'+`y_d',4) if `touse'
		gen `flag2'=1 if (`dayn'>=29 & `over12'==2 & `cond1'~=0 & `touse') | (`dayn'>=30 & `over12'==2 & `cond1'==0 & `touse')
		replace `over12'=`over12'+1 if `flag2'==1 & `touse'
		replace `dayn'=1 if `flag2'==1 & `touse'
		drop `flag2'

		
		*** Fixing Dec 31 ****

		gen `flag2'=1 if `over12'==12 & `excess'==0 & `day'==31 & `touse'

		replace `over12'=1 if `flag2'==1 & `touse'
		replace `over12'=1 if `flag2'==1 & `touse'
		replace `dayn'=1 if `flag2'==1 & `touse'
		replace `year'=`year'+1 if `flag2'==1 & `touse'


		*** Generate the date
		
		replace `cdate'=mdy(`over12',`dayn',`year'+`y_d') if `touse'
		replace `cdate'=mdy(12,1,`year'+`y_d') if `over12'==0 & `touse'
		
		
	}
	
	format `cdate' %td
end























capture program drop cutoff_old
qui program define cutoff_old

	syntax varlist(max=1) [if] [in], CDate(name) Mon(varname)

	qui {	
		tokenize `varlist'
		args bdate
		
		marksample touse
			
		tempvar day month year y_d m_d over12 cond1 dayn flag1 flag2 excess
		
		gen `day'=day(`bdate') if `touse' 
		gen `month'=month(`bdate') if `touse' 
		gen `year'=year(`bdate') if `touse' 
		
		gen `cdate' = .
		
		if `mon'==0 {
			gen `cdate'=`bdate' if `touse'
		}
		else if `mon'>0 { 
		
			gen `y_d'=floor(`mon'/12) if `touse' 
			gen `m_d'=mod(`mon',12) if `touse' 
			gen `over12'=(`month'+`m_d') if `touse'       // --> this could be over 12! 
			
			gen `dayn'=`day'-1 if `touse'
			replace `over12'=`over12'-1 if `dayn'==0 & `touse'
			gen `excess'=mod(`over12',12) if `touse'   

			replace `y_d'=`y_d'+1 if `over12'>12 & `touse'
			gen `cond1'=mod(`year'+`y_d',4) if `touse'
						
			replace `over12'=`over12' -1 if `dayn'==0 & `touse'
			replace `excess'=12 if `excess'==0 & `touse'
			replace `dayn'=31 if `dayn'==0 & inlist(`excess',1,3,5,7,8,10,12) & `touse'
			replace `dayn'=30 if `dayn'==0 & ~inlist(`excess',1,3,5,7,8,10,12) & `touse'
			replace `dayn'=29 if `dayn'==0 & inlist(`over12',2) & `cond1'==0 & `touse'
			replace `dayn'=28 if `dayn'==0 & inlist(`over12',2) & `cond1'~=0 & `touse'
			replace `dayn'=30 if `dayn'>=31 & ~inlist(`excess',1,3,5,7,8,10,12) & `touse'
						
			replace `dayn'=29 if `excess'==2 & `dayn'>28 & `cond1'==0 & `touse'
			replace `dayn'=28 if `excess'==2 & `dayn'>28 & `cond1'~=0 & `touse'
	
			replace `cdate'=mdy(`excess',`dayn',`year'+`y_d') if `touse'
			replace `cdate'=mdy(`excess',`dayn',`year') if `over12'<0 & `touse'
		
		}
				
		else {

			gen `y_d'=floor(`mon'/12) if `touse' 
			gen `m_d'=mod(`mon',12) if `touse' 
			gen `over12'=(`month'+`m_d') if `touse'   // --> this could be over 12!
			gen `excess'=mod(`over12',12)  if `touse'
			
			gen `dayn'=`day'+1 if `touse'
			gen `flag1'=1 if (`dayn'>31 & inlist(`excess',0,1,3,5,7,8,10,12)  & `touse') | (`dayn'>30 & ~inlist(`excess',0,1,3,5,7,8,10,12)  & `touse')
			replace `over12'=`over12'+1 if `flag1'==1 & `excess'~=0 & `over12'~=12 & `touse'
		
			replace `year'=`year'+1 if `over12'>12 & `touse'		
			replace `over12'=mod(`over12', 12) if `over12'>12 & `touse'
			
			replace `dayn'=1 if `flag1'==1 & `touse'		

			
			*** Fixing leap years *** 	
			
			gen `cond1'=mod(`year'+`y_d',4) if `touse'
			gen `flag2'=1 if (`dayn'>=29 & `over12'==2 & `cond1'~=0 & `touse') | (`dayn'>=30 & `over12'==2 & `cond1'==0 & `touse')
			replace `over12'=`over12'+1 if `flag2'==1 & `touse'
			replace `dayn'=1 if `flag2'==1 & `touse'
			drop `flag2'

			
			*** Fixing Dec 31 ****

			gen `flag2'=1 if `over12'==12 & `excess'==0 & `day'==31 & `touse'

			replace `over12'=1 if `flag2'==1 & `touse'
			replace `over12'=1 if `flag2'==1 & `touse'
			replace `dayn'=1 if `flag2'==1 & `touse'
			replace `year'=`year'+1 if `flag2'==1 & `touse'
	
	
			*** Generate the date
			
			replace `cdate'=mdy(`over12',`dayn',`year'+`y_d') if `touse'
			replace `cdate'=mdy(12,1,`year'+`y_d') if `over12'==0 & `touse'
			
			
		}
		
		format `cdate' %td
	}

end







