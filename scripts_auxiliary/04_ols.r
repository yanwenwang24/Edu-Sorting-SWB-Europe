## ------------------------------------------------------------------------
##
## Script name: 04_ols.r
## Purpose: Analyses using OLS regressions
## Author: Yanwen Wang
## Date Created: 2024-12-02
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:

## ------------------------------------------------------------------------

# 1 Load libraries and data -----------------------------------------------

# Load libraries
library(arrow)
library(gnm)
library(jtools)
library(lmtest)
library(tidyverse)

# Load data
sample <- read_feather("Datasets_tidy/sample.arrow")

# Categorize education
sample <- sample %>%
  mutate(
    edu4_pair = paste0(edu4_r, edu4_s),
    edu4_pair = factor(edu4_pair)
  ) %>%
  mutate(
    edu4_r = factor(edu4_r),
    edu4_s = factor(edu4_s)
  )

# Remove one country and one round (for dummy variable trap)
sample <- select(sample, -essround_10, -cntry_AT)

# Stratify the sample by gender
sample_men <- filter(sample, female == 0)
sample_women <- filter(sample, female == 1)

# Standardize age and household size
sample_men$age_scale <- scale(sample_men$age)
sample_women$age_scale <- scale(sample_women$age)
sample_men$hhsize_scale <- scale(sample_men$hhsize)
sample_women$hhsize_scale <- scale(sample_women$hhsize)

# 2 Fomulas ---------------------------------------------------------------

# Difference measures
fmla_diff <- as.formula(paste0(
  "lsat ~",
  "edu4_r + hyper4 + hypo4 + ",
  "age_scale + cohabit + divorce +
  immigrant + minority + hhsize_scale + child_count + child_under6_present +
  uempl + hincfel + ",
  paste(grep("essround_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  paste(grep("cntry_", names(sample), value = TRUE), collapse = "+")
))

# Compound measures
fmla_compound <- as.formula(paste0(
  "lsat ~",
  "edu4_pair + ",
  "age_scale + cohabit + divorce +
  immigrant + minority + hhsize_scale + child_count + child_under6_present +
  uempl + hincfel + ",
  paste(grep("essround_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  paste(grep("cntry_", names(sample), value = TRUE), collapse = "+")
))

# Interaction
fmla_inter <- as.formula(paste0(
  "lsat ~",
  "edu4_r*edu4_s + ",
  "age_scale + cohabit + divorce +
  immigrant + minority + hhsize_scale + child_count + child_under6_present +
  uempl + hincfel + ",
  paste(grep("essround_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  paste(grep("cntry_", names(sample), value = TRUE), collapse = "+")
))

# 3 Fit models -----------------------------------------------------------

# 3.1 Difference measures ------------------------------------------------

# Men
mod_diff_men <- lm(
  fmla_diff,
  data = sample_men,
  weights = anweight
)

summ(mod_diff_men, digits = 3)

# Women
mod_diff_women <- lm(
  fmla_diff,
  data = sample_women,
  weights = anweight
)

summ(mod_diff_women, digits = 3)

# 3.2 Compound measures -------------------------------------------------

# Men
mod_compound_men <- lm(
  fmla_compound,
  data = sample_men,
  weights = anweight
)

summ(mod_compound_men, digits = 3)

# Women
mod_compound_women <- lm(
  fmla_compound,
  data = sample_women,
  weights = anweight
)

summ(mod_compound_women, digits = 3)

# 3.3 Interaction models -----------------------------------------------

# Men
mod_inter_men <- lm(
  fmla_inter,
  data = sample_men,
  weights = anweight
)

summ(mod_inter_men, digits = 3)

# Women
mod_inter_women <- lm(
  fmla_inter,
  data = sample_women,
  weights = anweight
)

summ(mod_inter_women, digits = 3)