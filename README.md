# Utilities for working with dates

The repo contains two programmes that help simplify operations with dates 

## Introduction

Working with dates in Stata is easy if using the built-in `datetime` functionality.
Yet, while it is straight forward to compute difference between dates in days, there is no easy way to compute
difference between dates in years, months and days, or their combinations. In addition, 
there is no easy way to calculate the date resulting from adding/subtracting a specific number of years/months to a date.
This repo contains two functions that provide such functionality.


## Installation

To load `dateUtilities`, include the following line in your do file:

```
qui do "https://raw.githubusercontent.com/goshevs/datediff/master/dateUtilities.ado"

```

## Programme `dateDiff`

`dateDiff` calculates the difference between two dates in years, months and/or days.


### Syntax

```
	dateDiff varlist [if] [in], GENerate(string) [Type(string) replace]
```
<br>

**Required arguments**


| input       | description            |
|-------------|------------------------|
| *varlist*   | two variables in Stata date format (%td); the date in the first variable should precede the date in the second variable within an observation|
| *GENerate*  | specifies the user-required output format; see below for details |

<br>

**Optional arguments**


| option         | description            |
|----------------|------------------------|
| *type*         | specified the type of calculation to be conducted, see below for details |
| *replace*      | replaces the varaibles specified in `GENerate` |


<br>

`GENerate` has the following general syntax:

`gen(years = varname1 months = varname2 days = varname3)` were `varname1` to `varname3` are
user-specified names of variables to be created. These variables will contain years, months and days respectively.

`GENerate` can also be specified in the following ways:

- `gen(years = varname)`: result is reported in years
- `gen(months = varname)`: result is reported in months
- `gen(days = varname)`: result is reported in days
- `gen(years = varname1 months = varname2)`: result is reported in years and months
- `gen(months = varname2 days = varname3)`: result is reported in months and days

<br>

`type` can take the following values:

- `age`: computation uses the logic of age calculation (the default). For example, 
one year is the period from Jan 15, 2018 to Jan 14, 2019.
- `time`: computation uses the logic of time calculation. For example, 
one year is the period from Jan 15, 2018 to Jan 15, 2019.

<br>

-----

## Programme `dateShift`

`dateShift` shifts a date forward or backward in time by a user-specified number of years, months and/or days.


### Syntax

```
	dateShift varlist(max=1) [if] [in], GENerate(name) step(string) ///
					[type(string) replace INConsistent(name)]
```
<br>

**Required arguments**


| argument    | description            |
|-------------|------------------------|
| *varlist*   | a `datetime` variable name|
| *GENerate*  | name of a new variable that will contain the output |
| *step*      | specifies the user-provided input format; see below for details  |

<br>

**Optional arguments**


| arguments      | description            |
|----------------|------------------------|
| *type*         | specified the type of calculation to be conducted, see below for details |
| *replace*      | replaces the varaibles specified in `GENerate` |
| *INConsistent* | flag for inconsistent backward shifts; see below for details |


<br>


`step` has the following general syntax:

`step(years = varname1 months = varname2 days = varname3)` were `varname1` to `varname3` are
user-specified names of variables that contain years, months and days respectively. 

`step` can also be specified in the following ways:

- `step(years = varname)`: move dates by years
- `step(months = varname)`: move dates by months
- `step(days = varname)`: move dates by days
- `step(years = varname1 months = varname2)`: move dates by years and months
- `step(months = varname2 days = varname3)`: move dates by months and days

Any variable specified in `step` has to be present in the dataset and has to have valid values. 
Valid values are positive or negative integers. Mixed input, e.g. negative months and positive days within 
an observation, are not supported at this time. However, it is possible to shift different observations in different directions 
and by different amounts.

<br>

`type` can take the following values:

- `age`: computation uses the logic of age calculation (the default), i.e. 
the length of the shift includes the start date. Therefore, one year is defined as 
the period from Jan 15, 2018 to Jan 14, 2019.
- `time`: computation uses the logic of time calculation, i.e. the length of the shift
does not include the start date. Therefore, one year in this case is defined as 
the period from Jan 15, 2018 to Jan 15, 2019.

<br>

**Note**: Backward shifts could exhibit *minor inconsistencies* due to the different number of
days months have. These inconsistencies manifest in a small number of corner cases 
such as end-of-the-month start dates that translate to end dates that do not exist (such 
as February 30th or June 31st). In such cases, the end date is set to the last valid date prior to the non-existent date.
For example, an age shift of October 30th backwards by one month yields September 30th. To flag inconsistent shifts, 
use option `INConsistent`. 


## Examples

Additional examples are available in examples.do

```
*** Move bdates by the specified values in variables year, month and day, using age principle of calculation
dateShift bdate, gen(newvar) step(years = year months = month days = day)

*** Compute date difference in years, months and days, using age principle of calculation
dateDiff bdate newvar, gen(years=years months = months days = days) replace

*** Move bdates by the specified values in variable month, using age principle of calculation
dateShift bdate, gen(newvar) step(months = month) replace 

*** Compute date difference in months, using age principle of calculation
dateDiff bdate newvar, gen(months = months) replace


*** Additional examples

*** Move bdates by the specified values in variables year and day, using time principle of calculation
dateShift bdate, gen(newvar) step(years = year days = day) type(time) replace

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
```
