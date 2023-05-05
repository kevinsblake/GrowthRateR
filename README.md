# GrowthRateR
Calculate bacterial growth rates from plate reader kinetics data in R

Growth curves are commonly used in a microbiological studies to quantify the impact of various changes on bacterial growth rate (e.g., nutrient availability, gene expression). Modern microbial growth experiments can be arrayed in multi-well plates with absorbance measurements taken automatically by a platereader, which can result in thousands of individual datapoints.

`GrowthRateR` calculates the maximal growth rate of bacterial cell cultures in such growth experiments. This is done by log-transforming growth curves and applying a rolling regression with a shifting window, such that the maximum slope of any of the regressions is the maximal growth rate. This approach is advantageous for bacterial growth curves which do not nicely fit a sigmoidal curve (a first step for other tools, such as [`growthcurver`](https://www.rdocumentation.org/packages/growthcurver/versions/0.3.1#)).

`GrowthRateR` includes two functions:

1. `growthrateR()`: Calculate maximal growth rate of the cultures in each well then merges with experimental metadata. Includes option to automatically pre-process plate reader output file. 
2. `growthrateR_single()`: Plot the growth curve, regressions, and maximal growth rate for a single well.


# Content

[Installation](#install)

[Pre-process](#pre-processing)

[Functions](#functions)

## Install

Install directly from GitHub:
```r
source("https://raw.github.com/kevinsblake/GrowthCurveR/main/growthrate.R")
```

Alternatively, can download and then install using the filepath:
```r
source("dir1/dir2/growthrate.R")
```

## Pre-processing

Load plate reader output data and platemap

```r
platefile <- read_excel("dir1/dir2/platefile.xlsx")
platemap <- read_excel("dir1/dir2/platemap.xlsx")

```

### Plate file formatting

Plate files must have a header containing: `time`, then each well (e.g., `A1` to `H12` for 96-well plates). The rows below contain the time of each measurement in hours (starting with zero) and the OD reading for each well. For example:

```r
> head(EXP20220626.clean)
    time    A1    A2    A3    A4    A5    A6    A7    A8    A9   A10   A11   A12    B1    B2    B3    B4    B5    B6    B7
1 0.0000 0.098 0.094 0.102 0.102 0.099 0.098 0.098 0.095 0.096 0.095 0.097 0.100 0.095 0.129 0.122 0.119 0.124 0.122 0.124
2 0.0833 0.098 0.094 0.101 0.101 0.098 0.098 0.098 0.094 0.096 0.094 0.096 0.099 0.095 0.129 0.122 0.119 0.123 0.122 0.124
3 0.1667 0.098 0.094 0.101 0.100 0.098 0.098 0.097 0.094 0.096 0.094 0.095 0.099 0.094 0.129 0.123 0.119 0.124 0.123 0.124
4 0.2500 0.097 0.094 0.101 0.100 0.098 0.098 0.097 0.094 0.096 0.094 0.095 0.099 0.094 0.131 0.124 0.121 0.126 0.124 0.127
5 0.3333 0.097 0.094 0.101 0.100 0.098 0.098 0.097 0.094 0.096 0.094 0.095 0.099 0.094 0.134 0.127 0.123 0.128 0.126 0.128
6 0.4167 0.097 0.094 0.100 0.099 0.098 0.098 0.097 0.094 0.096 0.094 0.095 0.099 0.094 0.138 0.131 0.127 0.132 0.130 0.132
```

If using the BioTek Gen5 program, editing to this format can be done automatically with the `plate.clean=TRUE` option.

IMPORTANT: check that the `time` column is numeric (e.g., 0, 10, 20) and that Excel hasn't auto-formatted it to `00:00:00 MM/DD/YYYY` format.

### Platemap file formatting

Platemap file must have a header containing `Well` followed by any additional metadata useful for downstream analyses (e.g., strain, drug, concentration). Do not include units. For example:

```r
  Well  code  gene  
1 A1    NA    NA   
2 A2    NA    NA   
3 A3    NA    NA   
4 A4    NA    NA   
5 A5    NA    NA   
6 A6    NA    NA 
```

The `Well` column must have each well in the platereader file (e.g., `A1` to `H12` for 96-well plates), but rows with blank metadata columns (i.e. NA) will be removed.

## Functions

### growthrateR()

#### Description

Calculate maximal growth rate of the cultures in each well then merges with experimental metadata. Includes option to automatically pre-process plate reader output file. 

#### Usage

```r
growthcurveR(platefile, platemap, timepoints=5, window=1, time.min=-Inf, time.max=Inf, plate.clean=FALSE)
```

#### Arguments

`platefile`     Dataframe containing plate reader data
`platemap`      Maps experimental metadata onto plate wells.
`timepoints`    The frequency measurements were taken (in minutes; default = 10)
`window`        The length of the window of the rolling regression (in hours; default = 1)
`time.min`      The lowest timepoint value used. All measurements before this time are masked. (default = -Inf)
`time.max`      The maximum timepoint value used. All measurements after this time are masked. (default = Inf)
`plate.clean`   Cleans BioTek Gen 5 plate reader output platefile before processing. (default = FALSE)

#### Examples

```r
# Generate growth rate df, with a window of 0.5 h, with platefile processing, ignoring measurements after 16h
df <- growthcurveR(EXP_platefile, EXP_platemap, window=0.5, time.max=16, plate.clean=TRUE)
```

### growthrateR_single()

#### Description

Plot the growth curve, regressions, and maximal growth rate for a single well.

#### Usage

```r
growthcurveR_single(platefile, timepoints=5, window=1, time.min=-Inf, time.max=Inf, plate.clean=FALSE, well)
```

#### Arguments

`platefile`     Dataframe containing plate reader data.
`timepoints`    The frequency measurements were taken (in minutes; default = 10)
`window`        The length of the window of the rolling regression (in hours; default = 1)
`time.min`      The lowest timepoint value used. All measurements before this time are masked. (default = -Inf)
`time.max`      The maximum timepoint value used. All measurements after this time are masked. (default = Inf)
`plate.clean`   Cleans BioTek Gen 5 plate reader output platefile before processing. (default = FALSE)
`well`          The well to be printed.

#### Examples

```r
# Generate growth curve of well A1
plot <- growthcurveR_single(EXP_platefile, EXP_platemap, window=0.5, time.max=16, plate.clean=TRUE, well="A1")
```

## References

- https://padpadpadpad.github.io/post/calculating-microbial-growth-rates-from-od-using-rolling-regression/
