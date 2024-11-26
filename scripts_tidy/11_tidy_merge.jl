## ------------------------------------------------------------------------
##
## Script name: 11_tidy_merge.jl
## Purpose: Merge all cleaned ESS datasets
## Author: Yanwen Wang
## Date Created: 2024-11-25
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Merge data -------------------------------------------------------------     

ESS = vcat(
    ESS1,
    ESS2,
    ESS2_IT,
    ESS3,
    ESS3_LV,
    ESS3_RO,
    ESS4,
    ESS4_AT,
    ESS4_LT,
    ESS5,
    ESS5_AT,
    ESS6,
    ESS7,
    ESS8,
    ESS9,
    ESS10
)

@transform!(ESS, :pid = 1:nrow(ESS))

# 3 Save data -------------------------------------------------------------

Arrow.write("Datasets_tidy/ESS.arrow", ESS)