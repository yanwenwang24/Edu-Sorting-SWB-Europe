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
using AlgebraOfGraphics
using Arrow
using CairoMakie
using CategoricalArrays
using DataFrames, DataFramesMeta
using Distributions
using FreqTables
using MakieThemes
using Random
using RCall
using Statistics
using StatsBase

set_theme!(theme_ggthemr(:fresh))

# Load data
ESS = DataFrame(Arrow.Table("Datasets_tidy/ESS.arrow"))
sample = DataFrame(Arrow.Table("Datasets_tidy/sample.arrow"))

# Load functions
include("dictionaries.jl")
include("functions.jl")

# Source scripts
@time include("01_sample.jl")
@time include("02_visualize.jl")
@time include("03_describe.jl")