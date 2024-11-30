## ------------------------------------------------------------------------
##
## Script name: 02_visualize.jl
## Purpose: Visualize trends in homogamy, hypergamy, and hypogamy
## Author: Yanwen Wang
## Date Created: 2024-11-26
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:

## ------------------------------------------------------------------------

# By cohort
trends_cohort = @chain sample begin
    @transform(:birthy = :year - :age)
    @groupby(:birthy)
    @combine(
        :Homogamy = mean(:homo4),
        :Hypergamy = mean(:hyper4),
        :Hypogamy = mean(:hypo4)
    )
end

trends_cohort_long = stack(
    trends_cohort,
    Not(:birthy),
    variable_name="type",
    value_name="percent"
)

# By cohort and region
trends_cohort_region = @chain sample begin
    @transform(:birthy = :year - :age)
    @groupby(:birthy, :region)
    @combine(
        :Homogamy = mean(:homo4),
        :Hypergamy = mean(:hyper4),
        :Hypogamy = mean(:hypo4)
    )
end

trends_cohort_region_long = stack(
    trends_cohort_region,
    Not(:birthy, :region),
    variable_name="type",
    value_name="percent"
)

# Plot
f = Figure(; size=(1000, 1000), fontsize=12)

by_cohort = data(trends_cohort_long) *
            mapping(
                :birthy => "Cohort",
                :percent => "Proportion",
                color=:type => "Type",
            ) *
            (smooth() + visual(Scatter))

by_cohort_region = data(trends_cohort_region_long) *
                   mapping(
                       :birthy => "Cohort",
                       :percent => "Proportion",
                       color=:type => "Type",
                       layout=:region
                   ) *
                   (smooth() + visual(Scatter))

by_cohort_plt = draw!(
    f[1, 1],
    by_cohort,
    scales(Color=(; palette=["#fd7f6f", "#7eb0d5", "#b2e061"]))
)

by_cohort_region_plt = draw!(
    f[2, 1],
    by_cohort_region,
    scales(Color=(; palette=["#fd7f6f", "#7eb0d5", "#b2e061"]))
)

legend!(f[:, 2], by_cohort_plt)

f

save("graphs/trends.png", f; px_per_unit=2)