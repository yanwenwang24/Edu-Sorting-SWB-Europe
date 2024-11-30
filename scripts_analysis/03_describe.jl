## ------------------------------------------------------------------------
##
## Script name: 03_describe.jl
## Purpose: Descriptive statistics
## Author: Yanwen Wang
## Date Created: 2024-11-26
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:

## ------------------------------------------------------------------------

# 1 Descriptive statistics ------------------------------------------------

# Select men and women
sample_men = @subset(sample, :female .== 0)
sample_women = @subset(sample, :female .== 1)

# 1.1 Continuous variables ------------------------------------------------

# Pooled sample
analyze_variables(
    sample,
    [
        :lsat,
        :female,
        :age,
        :cohabit,
        :divorce,
        :immigrant, 
        :minority, 
        :hhsize, 
        :child_count, 
        :child_under6_present,
        :uempl,
        :hincfel
        ],
    weights=:anweight
) |> println

# Men
analyze_variables(
    sample_men,
    [
        :lsat,
        :female,
        :age,
        :cohabit,
        :divorce,
        :immigrant, 
        :minority, 
        :hhsize, 
        :child_count, 
        :child_under6_present,
        :uempl,
        :hincfel
        ],
    weights=:anweight
) |> println

# Women
analyze_variables(
    sample_women,
    [
        :lsat,
        :female,
        :age,
        :cohabit,
        :divorce,
        :immigrant, 
        :minority, 
        :hhsize, 
        :child_count, 
        :child_under6_present,
        :uempl,
        :hincfel
        ],
    weights=:anweight
) |> println

# 1.2 Categorical variables ------------------------------------------------

prop(freqtable(sample, :edu5_r, weights=sample.anweight))
prop(freqtable(sample_men, :edu5_r, weights=sample_men.anweight))
prop(freqtable(sample_women, :edu5_r, weights=sample_women.anweight))

# 1.3 T-tests --------------------------------------------------------------

weighted_ttest(
    sample_men.lsat,
    sample_women.lsat,
    sample_men.anweight,
    sample_women.anweight
)

weighted_ttest(
    sample_men.age,
    sample_women.age,
    sample_men.anweight,
    sample_women.anweight
)

weighted_ttest(
    sample_men.cohabit,
    sample_women.cohabit,
    sample_men.anweight,
    sample_women.anweight
)

weighted_ttest(
    sample_men.divorce,
    sample_women.divorce,
    sample_men.anweight,
    sample_women.anweight
)

weighted_ttest(
    sample_men.immigrant,
    sample_women.immigrant,
    sample_men.anweight,
    sample_women.anweight
)

weighted_ttest(
    sample_men.minority,
    sample_women.minority,
    sample_men.anweight,
    sample_women.anweight
)

weighted_ttest(
    sample_men.hhsize,
    sample_women.hhsize,
    sample_men.anweight,
    sample_women.anweight
)

weighted_ttest(
    sample_men.child_count,
    sample_women.child_count,
    sample_men.anweight,
    sample_women.anweight
)

weighted_ttest(
    sample_men.child_under6_present,
    sample_women.child_under6_present,
    sample_men.anweight,
    sample_women.anweight
)

weighted_ttest(
    sample_men.uempl,
    sample_women.uempl,
    sample_men.anweight,
    sample_women.anweight
)

weighted_ttest(
    sample_men.hincfel,
    sample_women.hincfel,
    sample_men.anweight,
    sample_women.anweight
)

# 2 Cross-tabulation ------------------------------------------------

prop(freqtable(sample, :edu5_m, :edu5_f, weights=sample.anweight), margins=1)

# 3 Sample size by country -------------------------------------------
cntry_df = @chain sample begin
    @select(:cntry, :region)
    unique
end

size_cntry = @chain sample begin
    @groupby(:cntry)
    @combine(:n = length(:cntry))
end

leftjoin!(cntry_df, size_cntry, on=:cntry)

# Rounds surveyed
rounds = Vector{Union{String,Missing}}(undef, nrow(cntry_df))

for i in 1:nrow(cntry_df)
    local cntry = cntry_df.cntry[i]
    local round_vector = sort(unique(@subset(sample, :cntry .== cntry)[!, :essround]), rev=true)
    rounds[i] = join(round_vector, ", ")
end

cntry_df[!, :rounds] = rounds

sort!(cntry_df, :region)

println(cntry_df)