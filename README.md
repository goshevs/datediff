## Utilities for working with dates

The repo contains two programmes that help compute differences between dates. 

### Introduction

Working with dates in Stata is made easy using its built-in `datetime` functionality.
Yet, while it is straight forward to compute difference between dates in days, there is no easy way to compute
difference between dates in years, months and days, or years or months only. In addition, 
there is no easy way to calculate the date resulting from adding a specific number of months to a start date.
This repo contains two functions that provide such functionality.

### Programme `datediff`

`datediff` calculates the difference between two dates in years, months and/or days.


Syntax
---

```
	datediff varlist(min=2 max=2), format(string) [replace]
```
<br>

**Required arguments**


| input       | description            |
|-------------|------------------------|
| *varlist*   | two variables in Stata date format |
| *format*    | specifies the user-required output; see below for details |

<br>

**Optional arguments**


| option         | description            |
|----------------|------------------------|
| *replace*      | replaces the varaibles specified in `format` |


<br>

`format` has the following general syntax:

`format(years = varname1 months = varname2 days = varname3)` were `varname1-varname3` are
user-specified names of variables to be created. These variables will contain years, months and days respectively.

`format` can be specified in the following ways:

- `format(years = varname)`: result is reported in years
- `format(months = varname)`: result is reported in months
- `format(days = varname)`: result is reported in days
- `format(years = varname1 months = varname2)`: result is reported in years and months
- `format(months = varname2 days = varname3)`: result is reported in months and days

Examples
---

Examples of usage are offered in file `examples.do`


### Programme `cutoff`

`cutoff` adds a user-specified number of months to a date


Syntax
---

```
	cutoff varlist(max=1) [if] [in], CDate(name) Mon(varname)
```
<br>

**Required arguments**


| input       | description            |
|-------------|------------------------|
| *varlist*   | a `datetime` varible name|
| *CDate*     | name of new variable to be created |
| *Mon*       | variable that contains the number of months to be added |

<br>

**NOTE: This command is currently under revision.**

Examples
---

Examples of usage will be offered shortly.





