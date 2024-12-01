## ------------------------------------------------------------------------
##
## Script name: 02.2.8_dmm_edu5_visualize.jl
## Purpose: Visualize model coefficients by region
## Author: Yanwen Wang
## Date Created: 2024-11-27
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:

## ------------------------------------------------------------------------

# Load data
dmm_region_summary = DataFrame(Arrow.Table("Datasets_tidy/dmm_region_edu5_summary.arrow"))
@transform!(dmm_region_summary, :se = 1.96 .* :se)

# Plot
f = Figure(; size=(800, 800), fontsize=12)

by_region = data(dmm_region_summary) * (
    mapping(
        :region => "",
        :coef => "Coefficient",
        :se,
        dodge_x=:gender => "Gender",
        color=:gender => "Gender",
        row=:pattern
    ) *
    visual(Errorbars) +
    mapping(
        :region => "",
        :coef => "Coefficient",
        dodge_x=:gender => "Gender",
        color=:gender => "Gender",
        row=:pattern
    ) *
    visual(Scatter)
)

hlines = mapping(0) * visual(HLines, color=(:grey, 0.5), linestyle=:dash)

plt = draw!(
    f[1, 1],
    by_region + hlines,
    scales(
        DodgeX=(; width=0.5),
        Color=(; palette=["#fd7f6f", "#7eb0d5", "#b2e061"])
    )
)

legend!(f[:, 2], plt)

f

save("graphs/dmm_region_edu5.png", f; px_per_unit=2)