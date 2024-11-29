## ------------------------------------------------------------------------
##
## Script name: 01_sample.jl
## Purpose: Restrict sample and construct variables
## Author: Yanwen Wang
## Date Created: 2024-11-26
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:

## ------------------------------------------------------------------------

# 1 Select sample ---------------------------------------------------------

# 1.1 Age 25-65 and living with a heterosexual partner --------------------

# Functions detailing sample selection rules
function sample_selection(age, mstat, oppsex)
    if ismissing(age) || ismissing(mstat) || ismissing(oppsex)
        return false
    end

    rule_age = age >= 25 && age <= 65
    rule_mstat = mstat == "married" || mstat == "cohabit"
    rule_oppsex = oppsex == 1

    return rule_age && rule_mstat && rule_oppsex
end

# Select samples based on the rules
sample = filter(
    [:age, :mstat, :oppsex] => sample_selection,
    ESS
)

sample = @chain sample begin
    @transform(:cohabit = recode(:mstat, "cohabit" => 1, "married" => 0))
end

# 1.2 Non-missing values for key variable --------------------------------

select!(
    sample,
    :pid,
    :year,
    :essround,
    :cntry,
    :anweight,
    :lsat,
    :female,
    :age,
    :cohabit,
    :divorce,
    :immigrant,
    :minority,
    :hincfel,
    :uempl,
    :hhsize,
    :child_count,
    :child_present,
    :child_under6_count,
    :child_under6_present,
    :edu5_r, :edu5_s, :edu5_m, :edu5_f,
    :edu4_r, :edu4_s, :edu4_m, :edu4_f,
    :edu3_r, :edu3_s, :edu3_m, :edu3_f,
    :heter5, :homo5, :hyper5, :hypo5,
    :heter4, :homo4, :hyper4, :hypo4,
    :heter3, :homo3, :hyper3, :hypo3
)

analyze_missing_values(sample) |> println

dropmissing!(sample)

# 1.3 Exclude certain countries -----------------------------------------

cntry_to_keep = @chain sample begin
    @select(:cntry, :essround)
    unique
    @groupby(:cntry)
    @combine(:n = length(:cntry))
    @subset(:n .>= 3)
end

sample = filter(row -> (row[:cntry] in cntry_to_keep.cntry), sample)
sample = filter(row -> !(row[:cntry] in ["IL"]), sample)

# Spread country and essround columns to dummy variables
sample = spread_to_dummies(sample, :cntry)
sample = spread_to_dummies(sample, :essround)

# 2 Contextual variables ------------------------------------------------

# 2.1 Region ------------------------------------------------------------

# Create new region column using dictionary mapping
transform!(sample,
    :cntry => ByRow(code -> get(region_dict, code, missing)) => :region
)

# 2.2 H-index for homogamy vs. heterogamy -------------------------------

# Calculate homogamy index by country/year
homo_index_df = @chain sample begin
    @groupby(:cntry, :year)
    @combine(
        :heter5 = sum(:heter5),
        :homo5 = sum(:homo5),
        :heter4 = sum(:heter4),
        :homo4 = sum(:homo4),
        :heter3 = sum(:heter3),
        :homo3 = sum(:homo3)
    )
    @transform(
        :homo5_index = log.(:homo5 ./ :heter5),
        :homo4_index = log.(:homo4 ./ :heter4),
        :homo3_index = log.(:homo3 ./ :heter3)
    )
    @select(:cntry, :year, :homo5_index, :homo4_index, :homo3_index)
end

leftjoin!(sample, homo_index_df, on=[:cntry, :year])

# 2.3 H-index for hypergamy vs. hypogamy -------------------------------

# Calculate hypogamy index by country/year
hyper_index_df = @chain sample begin
    @groupby(:cntry, :year)
    @combine(
        :hyper5 = sum(:hyper5),
        :hypo5 = sum(:hypo5),
        :hyper4 = sum(:hyper4),
        :hypo4 = sum(:hypo4),
        :hyper3 = sum(:hyper3),
        :hypo3 = sum(:hypo3)
    )
    @transform(
        :hyper5_index = log.(:hyper5 ./ :hypo5),
        :hyper4_index = log.(:hyper4 ./ :hypo4),
        :hyper3_index = log.(:hyper3 ./ :hypo3)
    )
    @select(:cntry, :year, :hyper5_index, :hyper4_index, :hyper3_index)
end

leftjoin!(sample, hyper_index_df, on=[:cntry, :year])

# 3 Save sample --------------------------------------------------------

Arrow.write("Datasets_tidy/sample.arrow", sample)