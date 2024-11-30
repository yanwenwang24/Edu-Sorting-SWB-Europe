## ------------------------------------------------------------------------
##
## Script name: 02.2.7_dmm_edu3_summary.r
## Purpose: Store coefficients and standard errors
## Author: Yanwen Wang
## Date Created: 2024-11-27
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:

## ------------------------------------------------------------------------

dmm_region_edu3_summary <- bind_rows(
  region_anglo,
  region_baltic,
  region_central,
  region_continental,
  region_nordic,
  region_southern
) %>%
  mutate(
    coef = `Estimate`,
    se = `Std. Error`,
    p = `Pr(>|t|)`
  ) %>%
  select(region, pattern, gender, coef, se, p, Df) %>%
  mutate(
    upper = coef + se * qt(0.975, df = Df),
    lower = coef - se * qt(0.975, df = Df)
  ) %>%
  mutate(
    pattern = case_when(
      pattern == "heter3" ~ "Heterogamy",
      pattern == "hyper3" ~ "Hypergamy",
      pattern == "hypo3" ~ "Hypogamy"
    )
  )

# Save to arrow
write_feather(
  dmm_region_edu3_summary,
  "Datasets_tidy/dmm_region_edu3_summary.arrow"
)