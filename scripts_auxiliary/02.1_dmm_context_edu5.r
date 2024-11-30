## ------------------------------------------------------------------------
##
## Script name: 02.1_dmm_context_edu5.r
## Purpose: Fit diagonal mobiliy models with H-index interaction terms
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

# Standardize age and household size
sample$age_scale <- scale(sample$age)
sample$hhsize_scale <- scale(sample$hhsize)

# Categorize education
sample <- sample %>%
  mutate(
    edu5_r = factor(edu5_r),
    edu5_s = factor(edu5_s)
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

# Baseline
fmla_base <- as.formula(paste0(
  "lsat ~",
  "-1 + age_scale + cohabit + divorce +
  immigrant + minority + hhsize_scale + child_count + child_under6_present +
  uempl + hincfel + ",
  paste(grep("essround_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  paste(grep("cntry_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  "Dref(edu5_r, edu5_s)"
))

# Heterogamy
fmla_heter <- as.formula(paste0(
  "lsat ~",
  "-1 + heter5 + homo5_index + hyper5_index + age_scale + cohabit + divorce +
  immigrant + minority + hhsize_scale + child_count + child_under6_present +
  uempl + hincfel + ",
  paste(grep("cntry_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  "Dref(edu5_r, edu5_s)"
))

fmla_heter_inter <- as.formula(paste0(
  "lsat ~",
  "-1 + heter5*homo5_index + heter5*hyper5_index + age_scale + 
  cohabit + divorce +
  immigrant + minority + hhsize_scale + child_count + child_under6_present +
  uempl + hincfel + ",
  paste(grep("cntry_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  "Dref(edu5_r, edu5_s)"
))

# Hypergamy and hypogamy
fmla_hyper <- as.formula(paste0(
  "lsat ~",
  "-1 + hyper5 + hypo5 + homo5_index + hyper5_index + age_scale + 
  cohabit + divorce +
  immigrant + minority + hhsize_scale + child_count + child_under6_present +
  uempl + hincfel + ",
  paste(grep("cntry_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  "Dref(edu5_r, edu5_s)"
))

fmla_hyper_inter <- as.formula(paste0(
  "lsat ~",
  "-1 + hyper5*homo5_index + hyper5*hyper5_index + 
  hypo5*homo5_index + hypo5*hyper5_index + age_scale + cohabit + divorce +
  immigrant + minority + hhsize_scale + child_count + child_under6_present +
  uempl + hincfel + ",
  paste(grep("cntry_", names(sample), value = TRUE), collapse = "+"),
  " + ",
  "Dref(edu5_r, edu5_s)"
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

# 3.2 Heterogamy ----------------------------------------------------------

# 3.2.1 Main model --------------------------------------------------------

# Men
mod_heter_men <- gnm(
  fmla_heter,
  data = sample_men,
  weights = anweight
)

summ(mod_heter_men, digits = 3)
print(DrefWeights(mod_heter_men), digits = 3)

# Women
mod_heter_women <- gnm(
  fmla_heter,
  data = sample_women,
  weights = anweight
)

summ(mod_heter_women, digits = 3)
print(DrefWeights(mod_heter_women), digits = 3)

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

# 3.2.2 Interaction model ------------------------------------------------

# Men
mod_heter_inter_men <- gnm(
  fmla_heter_inter,
  data = sample_men,
  weights = anweight
)

summ(mod_heter_inter_men, digits = 3)
print(DrefWeights(mod_heter_inter_men), digits = 3)
lrtest(mod_heter_inter_men, mod_heter_men)

# Women
mod_heter_inter_women <- gnm(
  fmla_heter_inter,
  data = sample_women,
  weights = anweight
)

summ(mod_heter_inter_women, digits = 3)
print(DrefWeights(mod_heter_inter_women), digits = 3)
lrtest(mod_heter_inter_women, mod_heter_women)

# Compare men vs. women
heter_inter_men_df <- se(mod_heter_inter_men) %>%
  as.data.frame() %>%
  rownames_to_column() %>%
  rename(
    estimate.men = Estimate,
    se.men = `Std. Error`
  )

heter_inter_women_df <- se(mod_heter_inter_women) %>%
  as.data.frame() %>%
  rownames_to_column() %>%
  rename(
    estimate.women = Estimate,
    se.women = `Std. Error`
  )

left_join(
  heter_inter_men_df,
  heter_inter_women_df,
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

# 3.3 Hypergamy and hypogamy --------------------------------------------

# 3.3.1 Main model ------------------------------------------------------

# Men
mod_hyper_men <- gnm(
  fmla_hyper,
  data = sample_men,
  weights = anweight
)

summ(mod_hyper_men, digits = 3)
print(DrefWeights(mod_hyper_men), digits = 3)

# Women
mod_hyper_women <- gnm(
  fmla_hyper,
  data = sample_women,
  weights = anweight
)

summ(mod_hyper_women, digits = 3)
print(DrefWeights(mod_hyper_women), digits = 3)

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

# 3.3.2 Interaction model -----------------------------------------------

# Men
mod_hyper_inter_men <- gnm(
  fmla_hyper_inter,
  data = sample_men,
  weights = anweight
)

summ(mod_hyper_inter_men, digits = 3)
print(DrefWeights(mod_hyper_inter_men), digits = 3)
lrtest(mod_hyper_inter_men, mod_hyper_men)

# Women
mod_hyper_inter_women <- gnm(
  fmla_hyper_inter,
  data = sample_women,
  weights = anweight
)

summ(mod_hyper_inter_women, digits = 3)
print(DrefWeights(mod_hyper_inter_women), digits = 3)
lrtest(mod_hyper_inter_women, mod_hyper_women)

# Compare men vs. women
hyper_inter_men_df <- se(mod_hyper_inter_men) %>%
  as.data.frame() %>%
  rownames_to_column() %>%
  rename(
    estimate.men = Estimate,
    se.men = `Std. Error`
  )

hyper_inter_women_df <- se(mod_hyper_inter_women) %>%
  as.data.frame() %>%
  rownames_to_column() %>%
  rename(
    estimate.women = Estimate,
    se.women = `Std. Error`
  )

left_join(
  hyper_inter_men_df,
  hyper_inter_women_df,
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