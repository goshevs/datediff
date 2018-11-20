## Utilities for working with dates

The repo contains two programmes that help simplify operations with dates 

### Introduction

Working with dates in Stata is easy if using its the built-in `datetime` functionality.
Yet, while it is straight forward to compute difference between dates in days, there is no easy way to compute
difference between dates in years, months and days, or their combinations. In addition, 
there is no easy way to calculate the date resulting from adding a specific number of years/months to a start date.
This repo contains two functions that provide such functionality.


### Installation

To load `dateUtilities`, include the following line in your do file:

```
do "https://raw.githubusercontent.com/goshevs/datediff/master/dateUtilities.ado"

```

### Programme `dateDiff`

`dateDiff` calculates the difference between two dates in years, months and/or days.


Syntax
---

```
	datediff varlist, GENerate(string) [Type(string) replace]
```
<br>

**Required arguments**


| input       | description            |
|-------------|------------------------|
| *varlist*   | two variables in Stata date format (%td) |
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

- `age`: computation uses the logic of age calculation. For example, 
one year is the period from Jan 15, 2018 to Jan 14, 2019.
- `time`: computation uses the logic of time calculation. For example, 
one year is the period from Jan 15, 2018 to Jan 15, 2019.


-----

### Programme `dateForward`

`dateForward` adds a user-specified number of years, months and/or days to a date.


Syntax
---

```
	dateforward varlist(max=1) [if] [in], GENerate(name) step(string) [type(string) replace]
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


<br>


`step` has the following general syntax:

`step(years = varname1 months = varname2 days = varname3)` were `varname1` to `varname3` are
user-specified names of variables that contain years, months and days respectively. 

`step` can also be specified in the following ways:

- `step(years = varname)`: move date forward by years
- `step(months = varname)`: move date forward by months
- `step(days = varname)`: move date forward by days
- `step(years = varname1 months = varname2)`: move date forward by years and months
- `step(months = varname2 days = varname3)`: move date forward by months and days

Any variable specified in `step` has to be present in the dataset and has to have valid values. 
Valid values are positive integers.

<br>

`type` can take the following values:

- `age`: computation uses the logic of age calculation. For example, 
one year is the period from Jan 15, 2018 to Jan 14, 2019.
- `time`: computation uses the logic of time calculation. For example, 
one year is the period from Jan 15, 2018 to Jan 15, 2019.



Examples (see examples.do for executable examples)
---

```
*** Move bdate forward by the specified years, months and days, using age principle of calculation
dateForward bdate, gen(newvar) step(years = year months = month days = day)

*** Compute date difference in years, months and days, using age principle of calculation
dateDiff bdate newvar, gen(years=years months = months days = days) replace

*** Move bdate forward by the specified months, using age principle of calculation
dateForward bdate, gen(newvar) step(months = month) replace 

*** Compute date difference in months, using age principle of calculation
dateDiff bdate newvar, gen(months = months) replace


*** Additional examples

*** Move bdate forward by the specified years and days, using time principle of calculation
dateForward bdate, gen(newvar) step(years = year days = day) type(time) replace

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
