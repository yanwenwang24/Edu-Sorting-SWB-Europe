## ------------------------------------------------------------------------
##
## Script name: 00_import.jl
## Purpose: Import packages, data
## Author: Yanwen Wang
## Date Created: 2024-11-26
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# Load the required packages
using Arrow
using CategoricalArrays
using DataFrames, DataFramesMeta
using FreqTables
using Random

# Load data
ESS = DataFrame(Arrow.Table("Datasets_tidy/ESS.arrow"))

# Load functions
include("dictionaries.jl")
include("functions.jl")

# Source scripts
@time include("01_sample.jl")