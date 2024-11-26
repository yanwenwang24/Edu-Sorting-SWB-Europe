## ------------------------------------------------------------------------
##
## Script name: 05_tidy_ESS5.jl
## Purpose: Clean ESS5 data
## Author: Yanwen Wang
## Date Created: 2024-11-25
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Load data -------------------------------------------------------------     

ESS5 = ESS["ESS5"]

# 2 Select and construct variables ----------------------------------------

# 2.1 Relationships --------------------------------------------------------

# Create unique ID
@transform!(ESS5, :pid = string.(Int.(:idno), :cntry))

# Select variables (relations, genders, year born)
ESS5_rship = select(ESS5, :pid, names(ESS5, r"^rship"))
ESS5_gndr = select(ESS5, :pid, names(ESS5, r"^gndr"))
select!(ESS5_gndr, Not(:gndr))
ESS5_yrbrn = select(ESS5, :pid, names(ESS5, r"^yrbrn"))
select!(ESS5_yrbrn, Not(:yrbrn))

# Transform into long format
ESS5_rship_long = stack(
    ESS5_rship,
    Not(:pid),
    variable_name="rank",
    value_name="rship"
)

ESS5_gndr_long = stack(
    ESS5_gndr,
    Not(:pid),
    variable_name="rank",
    value_name="gndr"
)

ESS5_yrbrn_long = stack(
    ESS5_yrbrn,
    Not(:pid),
    variable_name="rank",
    value_name="yrbrn"
)

# Clean up rank column to keep only numbers
transform!(
    ESS5_rship_long,
    :rank => ByRow(x -> replace(string(x), "rshipa" => "")) => :rank
)

transform!(
    ESS5_gndr_long,
    :rank => ByRow(x -> replace(string(x), "gndr" => "")) => :rank
)

transform!(
    ESS5_yrbrn_long,
    :rank => ByRow(x -> replace(string(x), "yrbrn" => "")) => :rank
)

ESS5_relations_long = leftjoin(ESS5_rship_long, ESS5_gndr_long, on=[:pid, :rank])
ESS5_relations_long = leftjoin(ESS5_relations_long, ESS5_yrbrn_long, on=[:pid, :rank])

# Get respondent's own gender and year born
ESS5_relations_long = leftjoin(
    ESS5_relations_long,
    select(ESS5, :pid, :gndr, :yrbrn),
    on=:pid,
    makeunique=true
)

# 2.2 Children ------------------------------------------------------------

ESS5_child = @chain ESS5_relations_long begin
    @subset(:rship .== 2)
    @groupby(:pid)
    @combine(:child_count = length(:pid))
    @transform(:child_count = ifelse.(:child_count .>= 3, 3, :child_count))
    @transform(:child_present = 1)
end

ESS5_child_under6 = @chain ESS5_relations_long begin
    @subset(:rship .== 2, :yrbrn .>= 2010 - 6)
    @groupby(:pid)
    @combine(:child_under6_count = length(:pid))
    @transform(:child_under6_count = ifelse.(:child_under6_count .>= 3, 3, :child_under6_count))
    @transform(:child_under6_present = 1)
end

leftjoin!(ESS5, ESS5_child, on=:pid)
leftjoin!(ESS5, ESS5_child_under6, on=:pid)

ESS5 = @chain ESS5 begin
    @transform(
        :child_count = coalesce.(:child_count, 0),
        :child_present = coalesce.(:child_present, 0),
        :child_under6_count = coalesce.(:child_under6_count, 0),
        :child_under6_present = coalesce.(:child_under6_present, 0)
    )
end

# 2.2 Identify whether has a heterosexual partner --------------------------

# Identify heterosexual relationships
ESS5_partnered = @subset(ESS5_relations_long, :rship .== 1)

oppsex = Vector{Union{Int,Missing}}(undef, nrow(ESS5_partnered))

for i in 1:nrow(ESS5_partnered)
    local gndr = ESS5_partnered.gndr_1[i]
    local gndr_sp = ESS5_partnered.gndr[i]

    if ismissing(gndr) || ismissing(gndr_sp)
        oppsex[i] = missing
    elseif gndr == gndr_sp
        oppsex[i] = 0
    elseif gndr != gndr_sp
        oppsex[i] = 1
    end
end

ESS5_partnered[!, :oppsex] = oppsex

# Identify those with multiple husband/wife/partner relationships
ESS5_multipartner = @chain ESS5_partnered begin
    @groupby(:pid)
    @combine(:n = length(:pid))
    @subset(:n .> 1)
    # Code oppsex as 2 for those with multiple relationships
    @transform(:oppsex = 2)
    @select(:pid, :oppsex)
end

leftjoin!(
    ESS5_partnered,
    ESS5_multipartner,
    on=:pid,
    makeunique=true
)

# Remove duplicates
ESS5_partnered = @chain ESS5_partnered begin
    @transform(:oppsex = coalesce.(:oppsex_1, :oppsex))
    @select(:pid, :oppsex)
    unique
end

# Merge back to the main dataset
leftjoin!(ESS5, ESS5_partnered, on=:pid)

# 2.3 Other variables of interest -----------------------------------------

# Select and rename variables
select!(
    ESS5,
    :pid,
    :essround,
    :cntry,
    :pspwght, :pweight,
    :stflife => :lsat,
    :gndr => :female,
    :agea => :age,
    :rshpsts,
    :brncntr => :immigrant,
    :blgetmg => :minority,
    :hhmmb => :hhsize,
    :dvrcdeva => :divorce,
    :eisced => :edu_r,
    :eiscedp => :edu_s,
    :pdjobev,
    :uempla, :uempli,
    :hincfel,
    :child_count, :child_present,
    :child_under6_count, :child_under6_present,
    :oppsex
)

ESS5 = @chain ESS5 begin
    @transform(:year = 2010)
    @transform(:female = recode(:female, 1 => 0, 2 => 1, missing => missing))
    @transform(:anweight = :pspwght .* :pweight)
    @transform(
        :immigrant = recode(:immigrant, 1 => 0, 2 => 1, missing => missing)
    )
    @transform(
        :minority = recode(:minority, 1 => 1, 2 => 0, missing => missing)
    )
    @transform(:hhsize =
        if ismissing(:hhsize)
            missing
        else
            min.(:hhsize, 6)
        end
    )
    @transform(
        :edu5_r = recode(
            :edu_r,
            1 => 1,
            2 => 2,
            3 => 3,
            4 => 3,
            5 => 4,
            6 => 5,
            7 => 5,
            55 => missing,
            missing => missing
        ),
        :edu5_s = recode(
            :edu_s,
            1 => 1,
            2 => 2,
            3 => 3,
            4 => 3,
            5 => 4,
            6 => 5,
            7 => 5,
            55 => missing,
            missing => missing
        )
    )
    @transform(
        :edu4_r = recode(
            :edu_r,
            1 => 1,
            2 => 1,
            3 => 2,
            4 => 2,
            5 => 3,
            6 => 4,
            7 => 4,
            55 => missing,
            missing => missing
        ),
        :edu4_s = recode(
            :edu_s,
            1 => 1,
            2 => 1,
            3 => 2,
            4 => 2,
            5 => 3,
            6 => 4,
            7 => 4,
            55 => missing,
            missing => missing
        )
    )
    @transform(
        :edu3_r = recode(
            :edu_r,
            1 => 1,
            2 => 1,
            3 => 2,
            4 => 2,
            5 => 3,
            6 => 3,
            7 => 3,
            55 => missing,
            missing => missing
        ),
        :edu3_s = recode(
            :edu_s,
            1 => 1,
            2 => 1,
            3 => 2,
            4 => 2,
            5 => 3,
            6 => 3,
            7 => 3,
            55 => missing,
            missing => missing
        )
    )
    @transform(:pdjobev = recode(:pdjobev, 1 => 1, 2 => 0, missing => missing))
    @transform(:uempl = ifelse.(:uempla .== 1 .|| :uempli .== 1, 1, 0))
    @transform(
        :mstat = recode(
            :rshpsts,
            1 => "married",
            2 => "married",
            3 => "cohabit",
            4 => "cohabit",
            5 => missing,
            6 => missing,
            missing => missing
        )
    )
    @transform(
        :divorce = recode(:divorce, 1 => 1, 2 => 0, missing => missing)
    )
end

# 2.4 Select variables ----------------------------------------------------

# Select and rename variables
select!(
    ESS5,
    :pid,
    :essround,
    :cntry,
    :anweight,
    :lsat,
    :female,
    :age,
    :mstat, :divorce,
    :immigrant,
    :minority,
    :hhsize,
    :edu5_r, :edu4_r, :edu3_r,
    :edu5_s, :edu4_s, :edu3_s,
    :pdjobev,
    :uempl,
    :hincfel,
    :child_count, :child_present,
    :child_under6_count, :child_under6_present,
    :oppsex
)

# 3 Save data -------------------------------------------------------------

Arrow.write("Datasets_tidy/ESS5.arrow", ESS5)