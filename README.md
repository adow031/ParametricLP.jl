| **Documentation** | **Build Status** | **Coverage** |
|:-----------------:|:--------------------:|:----------------:|
| [![][docs-latest-img]][docs-latest-url] | [![Build Status][build-img]][build-url] | [![Codecov branch][codecov-img]][codecov-url]

# ParametricLP.jl

This package utilises JuMP to define a two-dimensional parametric of the dual solution of a linear programme,
as a function of the two right-hand side values. If you use this package for academic work, please cite this paper:
Habibian M. et al. Co-optimization of demand response and interruptible load reserve offers for a price-making major
consumer. Energy Systems, 11, pp. 45-71, (2020).

## Example

There is an example based on a two-node electricity dispatch problem provided in the examples folder.

## Issues

This package has not yet been extensively tested. If you encounter any problems when using this package,
submit an issue.

[build-img]: https://github.com/adow031/ParametricLP/workflows/CI/badge.svg?branch=main
[build-url]: https://github.com/adow031/ParametricLP/actions?query=workflow%3ACI

[codecov-img]: https://codecov.io/github/adow031/ParametricLP/coverage.svg?branch=main
[codecov-url]: https://codecov.io/github/adow031/ParametricLP?branch=main

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://adow031.github.io/JuliaPkgTemplate
