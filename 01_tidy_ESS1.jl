## ------------------------------------------------------------------------
##
## Script name: 01_ESS1.jl
## Purpose: Clean ESS1 data
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

ESS1 = ESS["ESS1"]

# 2 Select and construct variables ----------------------------------------

# 2.1 Relationships --------------------------------------------------------

# Create unique ID
@transform!(ESS1, :pid = string.(Int.(:idno), :cntry))

# Select variables (relations, genders, year born)
ESS1_rship = select(ESS1, :pid, names(ESS1, r"^rship"))
ESS1_gndr = select(ESS1, :pid, names(ESS1, r"^gndr"))
select!(ESS1_gndr, Not(:gndr))
ESS1_yrbrn = select(ESS1, :pid, names(ESS1, r"^yrbrn"))
select!(ESS1_yrbrn, Not(:yrbrn))

# Transform into long format
ESS1_rship_long = stack(
    ESS1_rship,
    Not(:pid),
    variable_name="rank",
    value_name="rship"
)

ESS1_gndr_long = stack(
    ESS1_gndr,
    Not(:pid),
    variable_name="rank",
    value_name="gndr"
)

ESS1_yrbrn_long = stack(
    ESS1_yrbrn,
    Not(:pid),
    variable_name="rank",
    value_name="yrbrn"
)

# Clean up rank column to keep only numbers
transform!(
    ESS1_rship_long,
    :rank => ByRow(x -> replace(string(x), "rship" => "")) => :rank
)

transform!(
    ESS1_gndr_long,
    :rank => ByRow(x -> replace(string(x), "gndr" => "")) => :rank
)

transform!(
    ESS1_yrbrn_long,
    :rank => ByRow(x -> replace(string(x), "yrbrn" => "")) => :rank
)

ESS1_relations_long = leftjoin(ESS1_rship_long, ESS1_gndr_long, on=[:pid, :rank])
ESS1_relations_long = leftjoin(ESS1_relations_long, ESS1_yrbrn_long, on=[:pid, :rank])

# Get respondent's own gender and year born
ESS1_relations_long = leftjoin(
    ESS1_relations_long,
    select(ESS1, :pid, :gndr, :yrbrn),
    on=:pid,
    makeunique=true
)

# 2.2 Children ------------------------------------------------------------

ESS1_child = @chain ESS1_relations_long begin
    @subset(:rship .== 2)
    @groupby(:pid)
    @combine(:child_count = length(:pid))
    @transform(:child_count = ifelse.(:child_count .>= 3, 3, :child_count))
    @transform(:child_present = 1)
end

ESS1_child_under6 = @chain ESS1_relations_long begin
    @subset(:rship .== 2, :yrbrn .>= 2002 - 6)
    @groupby(:pid)
    @combine(:child_under6_count = length(:pid))
    @transform(:child_under6_count = ifelse.(:child_under6_count .>= 3, 3, :child_under6_count))
    @transform(:child_under6_present = 1)
end

leftjoin!(ESS1, ESS1_child, on=:pid)
leftjoin!(ESS1, ESS1_child_under6, on=:pid)

ESS1 = @chain ESS1 begin
    @transform(
        :child_count = coalesce.(:child_count, 0),
        :child_present = coalesce.(:child_present, 0),
        :child_under6_count = coalesce.(:child_under6_count, 0),
        :child_under6_present = coalesce.(:child_under6_present, 0)
    )
end

# 2.2 Identify whether has a heterosexual partner --------------------------

# Identify heterosexual relationships
ESS1_partnered = @subset(ESS1_relations_long, :rship .== 1)

oppsex = Vector{Union{Int,Missing}}(undef, nrow(ESS1_partnered))

for i in 1:nrow(ESS1_partnered)
    local gndr = ESS1_partnered.gndr_1[i]
    local gndr_sp = ESS1_partnered.gndr[i]

    if ismissing(gndr) || ismissing(gndr_sp)
        oppsex[i] = missing
    elseif gndr == gndr_sp
        oppsex[i] = 0
    elseif gndr != gndr_sp
        oppsex[i] = 1
    end
end

ESS1_partnered[!, :oppsex] = oppsex

# Identify those with multiple husband/wife/partner relationships
ESS1_multipartner = @chain ESS1_partnered begin
    @groupby(:pid)
    @combine(:n = length(:pid))
    @subset(:n .> 1)
    # Code oppsex as 2 for those with multiple relationships
    @transform(:oppsex = 2)
    @select(:pid, :oppsex)
end

leftjoin!(
    ESS1_partnered,
    ESS1_multipartner,
    on=:pid,
    makeunique=true
)

# Remove duplicates
ESS1_partnered = @chain ESS1_partnered begin
    @transform(:oppsex = coalesce.(:oppsex_1, :oppsex))
    @select(:pid, :oppsex)
    unique
end

# Merge back to the main dataset
leftjoin!(ESS1, ESS1_partnered, on=:pid)

# 2.3 Other variables of interest -----------------------------------------

# Select and rename variables
select!(
    ESS1,
    :pid,
    :essround,
    :cntry,
    :pspwght, :pweight,
    :stflife => :lsat,
    :gndr => :female,
    :agea => :age,
    :marital,
    :lvghw,
    :lvgoptn,
    :lvgptn,
    :brncntr => :immigrant,
    :blgetmg => :minority,
    :hhmmb => :hhsize,
    :dvrcdev,
    :edulvla => :edu_r,
    :edulvlpa => :edu_s,
    :pdjobev,
    :uempla, :uempli,
    :hincfel,
    :child_count, :child_present,
    :child_under6_count, :child_under6_present,
    :oppsex
)

ESS1 = @chain ESS1 begin
    @transform(:year = 2002)
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
            4 => 4,
            5 => 5,
            55 => missing,
            missing => missing
        ),
        :edu5_s = recode(
            :edu_s,
            1 => 1,
            2 => 2,
            3 => 3,
            4 => 4,
            5 => 5,
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
            4 => 3,
            5 => 4,
            55 => missing,
            missing => missing
        ),
        :edu4_s = recode(
            :edu_s,
            1 => 1,
            2 => 1,
            3 => 2,
            4 => 3,
            5 => 4,
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
            4 => 3,
            5 => 3,
            55 => missing,
            missing => missing
        ),
        :edu3_s = recode(
            :edu_s,
            1 => 1,
            2 => 1,
            3 => 2,
            4 => 3,
            5 => 3,
            55 => missing,
            missing => missing
        )
    )
    @transform(:pdjobev = recode(:pdjobev, 1 => 1, 2 => 0, missing => missing))
    @transform(:uempl = ifelse.(:uempla .== 1 .|| :uempli .== 1, 1, 0))
end

# Married vs. cohabiting vs. other
mstat = Vector{Union{String,Missing}}(undef, nrow(ESS1))

for i in 1:nrow(ESS1)
    local lvghw = coalesce(ESS1.lvghw[i], 99)
    local lvgptn = coalesce(ESS1.lvgptn[i], 99)
    local lvgoptn = coalesce(ESS1.lvgoptn[i], 99)

    if lvghw == 1 # Living with husband/wife
        mstat[i] = "married"
    elseif lvgoptn == 1 # Living with other partner
        mstat[i] = "cohabit"
    elseif lvgptn == 1 # Living with partner
        mstat[i] = "cohabit"
    else # Set all else to missing
        mstat[i] = missing
    end
end

ESS1[!, :mstat] = mstat

# Ever-divorced
divorce = Vector{Union{Int,Missing}}(undef, nrow(ESS1))

for i in 1:nrow(ESS1)
    local marital = coalesce(ESS1.:marital[i], 99)
    local dvrcdev = coalesce(ESS1.:dvrcdev[i], 99)

    if marital == 3 || dvrcdev == 1
        divorce[i] = 1
    elseif marital == 5 || dvrcdev == 2
        divorce[i] = 0
    else
        divorce[i] = missing
    end
end

ESS1[!, :divorce] = divorce

# 2.4 Select variables ----------------------------------------------------

# Select and rename variables
select!(
    ESS1,
    :pid,
    :essround,
    :cntry,
    :anweight,
    :lsat,
    :female,
    :age,
    :marital, :mstat, :divorce,
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

Arrow.write("Datasets_tidy/ESS1.arrow", ESS1)