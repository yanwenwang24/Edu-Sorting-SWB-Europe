## ------------------------------------------------------------------------
##
## Script name: 00_tidy_main.jl
## Purpose: Master file to tidy the raw data
## Author: Yanwen Wang
## Date Created: 2024-11-25
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
using Random
using RData
using StatsBase

# Load data, dictionaries and functions
ESS = load("Datasets_raw/ESS.RData")

# Source scripts
@time include("01_tidy_ESS1.jl")
@time include("02_tidy_ESS2.jl")
@time include("02.1_tidy_ESS2_IT.jl")