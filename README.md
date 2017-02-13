# TESP package for MATLAB
Support for processing output files and generating large sets of input files for [TESP](https://github.com/aleixpinardell/tesp) ([Tudat](https://github.com/Tudat) Earth Satellite Propagator) in MATLAB.

Currently in Beta. Documentation incomplete. This package has only been partially tested in MATLAB R2016b.

Manual installation:
1. Clone or [download](https://github.com/aleixpinardell/matlab-tesp/archive/master.zip) this repository into your MATLAB's directory, typically `~/Documents/MATLAB`.
2. Rename the created directory to `+tesp` (the plus sign indicates MATLAB that this directory is a package).
3. Start using the package by running commands such as:
```
tesp.transform.epochToDate(0)
tesp.support.isCartesianState([-7e6 0 0 0 8e3 0])
tesp.results('myOutputFile.tespout')
```
