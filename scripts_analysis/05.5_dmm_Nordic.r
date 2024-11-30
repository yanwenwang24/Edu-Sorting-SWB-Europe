## ------------------------------------------------------------------------
##
## Script name: 05.5_dmm_Nordic.r
## Purpose: Fit diagonal mobiliy models in Nordic countries
## Author: Yanwen Wang
## Date Created: 2024-11-27
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
    edu4_r = factor(edu4_r),
    edu4_s = factor(edu4_s)
  )

# Remove one round (for dummy variable trap)
sample <- select(sample, -essround_10)

# Stratify the sample by gender
sample_men <- filter(sample, region == "Nordic", female == 0)
sample_women <- filter(sample, region == "Nordic", female == 1)

# Standardize age and household size
sample_men$age_scale <- scale(sample_men$age)
sample_women$age_scale <- scale(sample_women$age)
sample_men$hhsize_scale <- scale(sample_men$hhsize)
sample_women$hhsize_scale <- scale(sample_women$hhsize)

# 2 Fomulas ---------------------------------------------------------------

# Baseline
fmla_base <- as.formula(paste0(
  "lsat ~",
  "-1 + age_scale + cohabit + divorce +
  immigrant + minority + hhsize_scale + child_count + child_under6_present +
  uempl + ",
  paste(grep("essround_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  "cntry_FI + cntry_NO + cntry_IS + cntry_SE",
  " + ",
  "Dref(edu4_r, edu4_s)"
))

# Heterogamy
fmla_heter <- as.formula(paste0(
  "lsat ~",
  "-1 + heter4 + age_scale + cohabit + divorce +
  immigrant + minority + hhsize_scale + child_count + child_under6_present +
  uempl + ",
  paste(grep("essround_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  "cntry_FI + cntry_NO + cntry_IS + cntry_SE",
  " + ",
  "Dref(edu4_r, edu4_s)"
))

# Hypergamy and hypogamy
fmla_hyper <- as.formula(paste0(
  "lsat ~",
  "-1 + hyper4 + hypo4 + age_scale + cohabit + divorce +
  immigrant + minority + hhsize_scale + child_count + child_under6_present +
  uempl + ",
  paste(grep("essround_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  "cntry_FI + cntry_NO + cntry_IS + cntry_SE",
  " + ",
  "Dref(edu4_r, edu4_s)"
))

# 3 Fit models -----------------------------------------------------------

set.seed(321)

# 3.1 Baseline ------------------------------------------------------------

# Men
mod_base_men <- gnm(
  fmla_base,
  data = sample_men,
  weights = anweight
)

summ(mod_base_men, digits = 3)
print(DrefWeights(mod_base_men), digits = 3)

# Women
mod_base_women <- gnm(
  fmla_base,
  data = sample_women,
  weights = anweight
)

summ(mod_base_women, digits = 3)
print(DrefWeights(mod_base_women), digits = 3)

# Compare men vs. women
base_men_df <- se(mod_base_men) %>%
  as.data.frame() %>%
  rownames_to_column() %>%
  rename(
    estimate.men = Estimate,
    se.men = `Std. Error`
  )

base_women_df <- se(mod_base_women) %>%
  as.data.frame() %>%
  rownames_to_column() %>%
  rename(
    estimate.women = Estimate,
    se.women = `Std. Error`
  )

left_join(
  base_men_df,
  base_women_df,
  by = "rowname"
) %>%
  mutate(z = (estimate.men - estimate.women) / sqrt(se.men^2 + se.women^2)) %>%
  mutate(
    p = 2 * pnorm(-abs(z)),
    p = round(p, 3)
  ) %>%
  mutate(
    star = case_when(
      p < 0.001 ~ "***",
      p < 0.01 ~ "**",
      p < 0.05 ~ "*",
      TRUE ~ "ns"
    )
  ) %>%
  select(rowname, z, p, star)

# 3.2 Heterogamy ----------------------------------------------------------

# Men
mod_heter_men <- gnm(
  fmla_heter,
  data = sample_men,
  weights = anweight
)

summ(mod_heter_men, digits = 3)
print(DrefWeights(mod_heter_men), digits = 3)
lrtest(mod_heter_men, mod_base_men)

# Women
mod_heter_women <- gnm(
  fmla_heter,
  data = sample_women,
  weights = anweight
)

summ(mod_heter_women, digits = 3)
print(DrefWeights(mod_heter_women), digits = 3)
lrtest(mod_heter_women, mod_base_women)

# Compare men vs. women
heter_men_df <- se(mod_heter_men) %>%
  as.data.frame() %>%
  rownames_to_column() %>%
  rename(
    estimate.men = Estimate,
    se.men = `Std. Error`
  )

heter_women_df <- se(mod_heter_women) %>%
  as.data.frame() %>%
  rownames_to_column() %>%
  rename(
    estimate.women = Estimate,
    se.women = `Std. Error`
  )

left_join(
  heter_men_df,
  heter_women_df,
  by = "rowname"
) %>%
  mutate(z = (estimate.men - estimate.women) / sqrt(se.men^2 + se.women^2)) %>%
  mutate(
    p = 2 * pnorm(-abs(z)),
    p = round(p, 3)
  ) %>%
  mutate(
    star = case_when(
      p < 0.001 ~ "***",
      p < 0.01 ~ "**",
      p < 0.05 ~ "*",
      TRUE ~ "ns"
    )
  ) %>%
  select(rowname, z, p, star)

# Get coefficients
sum_heter_men <- summary(mod_heter_men)
sum_heter_women <- summary(mod_heter_women)

region_nordic_heter_men <- sum_heter_men$coefficients %>%
  as.data.frame() %>%
  filter(row_number() == 1) %>%
  mutate(Df = summary(mod_heter_men)$df[2]) %>%
  rownames_to_column() %>%
  rename(pattern = rowname) %>%
  mutate(gender = "men")

region_nordic_heter_women <- sum_heter_women$coefficients %>%
  as.data.frame() %>%
  filter(row_number() == 1) %>%
  mutate(Df = summary(mod_heter_women)$df[2]) %>%
  rownames_to_column() %>%
  rename(pattern = rowname) %>%
  mutate(gender = "women")

region_nordic_heter <- bind_rows(
  region_nordic_heter_men,
  region_nordic_heter_women
) %>%
  mutate(region = "Nordic")

# 3.3 Hypergamy and hypogamy --------------------------------------------

# Men
mod_hyper_men <- gnm(
  fmla_hyper,
  data = sample_men,
  weights = anweight
)

summ(mod_hyper_men, digits = 3)
print(DrefWeights(mod_hyper_men), digits = 3)
lrtest(mod_hyper_men, mod_base_men)

# Women
mod_hyper_women <- gnm(
  fmla_hyper,
  data = sample_women,
  weights = anweight
)

summ(mod_hyper_women, digits = 3)
print(DrefWeights(mod_hyper_women), digits = 3)
lrtest(mod_hyper_women, mod_base_women)

# Compare men vs. women
hyper_men_df <- se(mod_hyper_men) %>%
  as.data.frame() %>%
  rownames_to_column() %>%
  rename(
    estimate.men = Estimate,
    se.men = `Std. Error`
  )

hyper_women_df <- se(mod_hyper_women) %>%
  as.data.frame() %>%
  rownames_to_column() %>%
  rename(
    estimate.women = Estimate,
    se.women = `Std. Error`
  )

left_join(
  hyper_men_df,
  hyper_women_df,
  by = "rowname"
) %>%
  mutate(z = (estimate.men - estimate.women) / sqrt(se.men^2 + se.women^2)) %>%
  mutate(
    p = 2 * pnorm(-abs(z)),
    p = round(p, 3)
  ) %>%
  mutate(
    star = case_when(
      p < 0.001 ~ "***",
      p < 0.01 ~ "**",
      p < 0.05 ~ "*",
      TRUE ~ "ns"
    )
  ) %>%
  select(rowname, z, p, star)

# Get coefficients
sum_hyper_men <- summary(mod_hyper_men)
sum_hyper_women <- summary(mod_hyper_women)

region_nordic_hyper_men <- sum_hyper_men$coefficients %>%
  as.data.frame() %>%
  filter(row_number() == 1 | row_number() == 2) %>%
  mutate(Df = summary(mod_hyper_men)$df[2]) %>%
  rownames_to_column() %>%
  rename(pattern = rowname) %>%
  mutate(gender = "men")

region_nordic_hyper_women <- sum_hyper_women$coefficients %>%
  as.data.frame() %>%
  filter(row_number() == 1 | row_number() == 2) %>%
  mutate(Df = summary(mod_hyper_women)$df[2]) %>%
  rownames_to_column() %>%
  rename(pattern = rowname) %>%
  mutate(gender = "women")

region_nordic_hyper <- bind_rows(
  region_nordic_hyper_men,
  region_nordic_hyper_women
) %>%
  mutate(region = "Nordic")

region_nordic <- bind_rows(
  region_nordic_heter,
  region_nordic_hyper
)