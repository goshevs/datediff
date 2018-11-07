*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* * Define a program to compute cutoff time properly
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


capture program drop cutoff
qui program define cutoff

	syntax varlist(max=1) [if] [in], CDate(name) [ Mon(varname)]

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
