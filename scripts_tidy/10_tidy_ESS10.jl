## ------------------------------------------------------------------------
##
## Script name: 10_tidy_ESS10.jl
## Purpose: Clean ESS10 data
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

ESS10 = ESS["ESS10"]

# 2 Select and construct variables ----------------------------------------

# 2.1 Relationships --------------------------------------------------------

# Create unique ID
@transform!(ESS10, :pid = string.(Int.(:idno), :cntry))

# Select variables (relations, genders, year born)
ESS10_rship = select(ESS10, :pid, names(ESS10, r"^rship"))
ESS10_gndr = select(ESS10, :pid, names(ESS10, r"^gndr"))
select!(ESS10_gndr, Not(:gndr))
ESS10_yrbrn = select(ESS10, :pid, names(ESS10, r"^yrbrn"))
select!(ESS10_yrbrn, Not(:yrbrn))

# Transform into long format
ESS10_rship_long = stack(
    ESS10_rship,
    Not(:pid),
    variable_name="rank",
    value_name="rship"
)

ESS10_gndr_long = stack(
    ESS10_gndr,
    Not(:pid),
    variable_name="rank",
    value_name="gndr"
)

ESS10_yrbrn_long = stack(
    ESS10_yrbrn,
    Not(:pid),
    variable_name="rank",
    value_name="yrbrn"
)

# Clean up rank column to keep only numbers
transform!(
    ESS10_rship_long,
    :rank => ByRow(x -> replace(string(x), "rshipa" => "")) => :rank
)

transform!(
    ESS10_gndr_long,
    :rank => ByRow(x -> replace(string(x), "gndr" => "")) => :rank
)

transform!(
    ESS10_yrbrn_long,
    :rank => ByRow(x -> replace(string(x), "yrbrn" => "")) => :rank
)

ESS10_relations_long = leftjoin(ESS10_rship_long, ESS10_gndr_long, on=[:pid, :rank])
ESS10_relations_long = leftjoin(ESS10_relations_long, ESS10_yrbrn_long, on=[:pid, :rank])

# Get respondent's own gender and year born
ESS10_relations_long = leftjoin(
    ESS10_relations_long,
    select(ESS10, :pid, :gndr, :yrbrn),
    on=:pid,
    makeunique=true
)

# 2.2 Children ------------------------------------------------------------

ESS10_child = @chain ESS10_relations_long begin
    @subset(:rship .== 2)
    @groupby(:pid)
    @combine(:child_count = length(:pid))
    @transform(:child_count = ifelse.(:child_count .>= 3, 3, :child_count))
    @transform(:child_present = 1)
end

ESS10_child_under6 = @chain ESS10_relations_long begin
    @subset(:rship .== 2, :yrbrn .>= 2020 - 6)
    @groupby(:pid)
    @combine(:child_under6_count = length(:pid))
    @transform(:child_under6_count = ifelse.(:child_under6_count .>= 3, 3, :child_under6_count))
    @transform(:child_under6_present = 1)
end

leftjoin!(ESS10, ESS10_child, on=:pid)
leftjoin!(ESS10, ESS10_child_under6, on=:pid)

ESS10 = @chain ESS10 begin
    @transform(
        :child_count = coalesce.(:child_count, 0),
        :child_present = coalesce.(:child_present, 0),
        :child_under6_count = coalesce.(:child_under6_count, 0),
        :child_under6_present = coalesce.(:child_under6_present, 0)
    )
end

# 2.2 Identify whether has a heterosexual partner --------------------------

# Identify heterosexual relationships
ESS10_partnered = @subset(ESS10_relations_long, :rship .== 1)

oppsex = Vector{Union{Int,Missing}}(undef, nrow(ESS10_partnered))

for i in 1:nrow(ESS10_partnered)
    local gndr = ESS10_partnered.gndr_1[i]
    local gndr_sp = ESS10_partnered.gndr[i]

    if ismissing(gndr) || ismissing(gndr_sp)
        oppsex[i] = missing
    elseif gndr == gndr_sp
        oppsex[i] = 0
    elseif gndr != gndr_sp
        oppsex[i] = 1
    end
end

ESS10_partnered[!, :oppsex] = oppsex

# Identify those with multiple husband/wife/partner relationships
ESS10_multipartner = @chain ESS10_partnered begin
    @groupby(:pid)
    @combine(:n = length(:pid))
    @subset(:n .> 1)
    # Code oppsex as 2 for those with multiple relationships
    @transform(:oppsex = 2)
    @select(:pid, :oppsex)
end

leftjoin!(
    ESS10_partnered,
    ESS10_multipartner,
    on=:pid,
    makeunique=true
)

# Remove duplicates
ESS10_partnered = @chain ESS10_partnered begin
    @transform(:oppsex = coalesce.(:oppsex_1, :oppsex))
    @select(:pid, :oppsex)
    unique
end

# Merge back to the main dataset
leftjoin!(ESS10, ESS10_partnered, on=:pid)

# 2.3 Other variables of interest -----------------------------------------

# Select and rename variables
select!(
    ESS10,
    :pid,
    :essround,
    :cntry,
    :pspwght, :pweight,
    :stflife => :lsat,
    :gndr => :female,
    :agea => :age,
    :rshpsts,
    :brncntr => :immigrant,
    :feethngr => :minority,
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

ESS10 = @chain ESS10 begin
    @transform(:year = 2020)
    @transform(:female = recode(:female, 1 => 0, 2 => 1, missing => missing))
    @transform(:anweight = :pspwght .* :pweight)
    @transform(
        :immigrant = recode(:immigrant, 1 => 0, 2 => 1, missing => missing)
    )
    @transform(
        :minority = recode(:minority, 1 => 0, 2 => 1, missing => missing)
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
    ESS10,
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

Arrow.write("Datasets_tidy/ESS10.arrow", ESS10)