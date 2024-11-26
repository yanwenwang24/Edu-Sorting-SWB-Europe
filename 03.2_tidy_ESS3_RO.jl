## ------------------------------------------------------------------------
##
## Script name: 03.2_tidy_ESS3_RO.jl
## Purpose: Clean ESS3_RO data
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

ESS3_RO = ESS["ESS3_RO"]

# 2 Select and construct variables ----------------------------------------

# 2.1 Relationships --------------------------------------------------------

# Create unique ID
@transform!(ESS3_RO, :pid = string.(Int.(:idno), :cntry))

# Select variables (relations, genders, year born)
ESS3_RO_rship = select(ESS3_RO, :pid, names(ESS3_RO, r"^rship"))
ESS3_RO_gndr = select(ESS3_RO, :pid, names(ESS3_RO, r"^gndr"))
select!(ESS3_RO_gndr, Not(:gndr))
ESS3_RO_yrbrn = select(ESS3_RO, :pid, names(ESS3_RO, r"^yrbrn"))
select!(ESS3_RO_yrbrn, Not(:yrbrn))

# Transform into long format
ESS3_RO_rship_long = stack(
    ESS3_RO_rship,
    Not(:pid),
    variable_name="rank",
    value_name="rship"
)

ESS3_RO_gndr_long = stack(
    ESS3_RO_gndr,
    Not(:pid),
    variable_name="rank",
    value_name="gndr"
)

ESS3_RO_yrbrn_long = stack(
    ESS3_RO_yrbrn,
    Not(:pid),
    variable_name="rank",
    value_name="yrbrn"
)

# Clean up rank column to keep only numbers
transform!(
    ESS3_RO_rship_long,
    :rank => ByRow(x -> replace(string(x), "rshipa" => "")) => :rank
)

transform!(
    ESS3_RO_gndr_long,
    :rank => ByRow(x -> replace(string(x), "gndr" => "")) => :rank
)

transform!(
    ESS3_RO_yrbrn_long,
    :rank => ByRow(x -> replace(string(x), "yrbrn" => "")) => :rank
)

ESS3_RO_relations_long = leftjoin(ESS3_RO_rship_long, ESS3_RO_gndr_long, on=[:pid, :rank])
ESS3_RO_relations_long = leftjoin(ESS3_RO_relations_long, ESS3_RO_yrbrn_long, on=[:pid, :rank])

# Get respondent's own gender and year born
ESS3_RO_relations_long = leftjoin(
    ESS3_RO_relations_long,
    select(ESS3_RO, :pid, :gndr, :yrbrn),
    on=:pid,
    makeunique=true
)

# 2.2 Children ------------------------------------------------------------

ESS3_RO_child = @chain ESS3_RO_relations_long begin
    @subset(:rship .== 2)
    @groupby(:pid)
    @combine(:child_count = length(:pid))
    @transform(:child_count = ifelse.(:child_count .>= 3, 3, :child_count))
    @transform(:child_present = 1)
end

ESS3_RO_child_under6 = @chain ESS3_RO_relations_long begin
    @subset(:rship .== 2, :yrbrn .>= 2006 - 6)
    @groupby(:pid)
    @combine(:child_under6_count = length(:pid))
    @transform(:child_under6_count = ifelse.(:child_under6_count .>= 3, 3, :child_under6_count))
    @transform(:child_under6_present = 1)
end

leftjoin!(ESS3_RO, ESS3_RO_child, on=:pid)
leftjoin!(ESS3_RO, ESS3_RO_child_under6, on=:pid)

ESS3_RO = @chain ESS3_RO begin
    @transform(
        :child_count = coalesce.(:child_count, 0),
        :child_present = coalesce.(:child_present, 0),
        :child_under6_count = coalesce.(:child_under6_count, 0),
        :child_under6_present = coalesce.(:child_under6_present, 0)
    )
end

# 2.2 Identify whether has a heterosexual partner --------------------------

# Identify heterosexual relationships
ESS3_RO_partnered = @subset(ESS3_RO_relations_long, :rship .== 1)

oppsex = Vector{Union{Int,Missing}}(undef, nrow(ESS3_RO_partnered))

for i in 1:nrow(ESS3_RO_partnered)
    local gndr = ESS3_RO_partnered.gndr_1[i]
    local gndr_sp = ESS3_RO_partnered.gndr[i]

    if ismissing(gndr) || ismissing(gndr_sp)
        oppsex[i] = missing
    elseif gndr == gndr_sp
        oppsex[i] = 0
    elseif gndr != gndr_sp
        oppsex[i] = 1
    end
end

ESS3_RO_partnered[!, :oppsex] = oppsex

# Identify those with multiple husband/wife/partner relationships
ESS3_RO_multipartner = @chain ESS3_RO_partnered begin
    @groupby(:pid)
    @combine(:n = length(:pid))
    @subset(:n .> 1)
    # Code oppsex as 2 for those with multiple relationships
    @transform(:oppsex = 2)
    @select(:pid, :oppsex)
end

leftjoin!(
    ESS3_RO_partnered,
    ESS3_RO_multipartner,
    on=:pid,
    makeunique=true
)

# Remove duplicates
ESS3_RO_partnered = @chain ESS3_RO_partnered begin
    @transform(:oppsex = coalesce.(:oppsex_1, :oppsex))
    @select(:pid, :oppsex)
    unique
end

# Merge back to the main dataset
leftjoin!(ESS3_RO, ESS3_RO_partnered, on=:pid)

# 2.3 Other variables of interest -----------------------------------------

# Select and rename variables
select!(
    ESS3_RO,
    :pid,
    :essround,
    :cntry,
    :pspwght, :pweight,
    :stflife => :lsat,
    :gndr => :female,
    :agea => :age,
    :maritala => :marital,
    :lvghwa,
    :lvgptna,
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

ESS3_RO = @chain ESS3_RO begin
    @transform(:year = 2006)
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
mstat = Vector{Union{String,Missing}}(undef, nrow(ESS3_RO))

for i in 1:nrow(ESS3_RO)
    local lvghwa = coalesce(ESS3_RO.lvghwa[i], 99)
    local lvgptna = coalesce(ESS3_RO.lvgptna[i], 99)

    if lvghwa == 1 # Living with husband/wife/civil partner
        mstat[i] = "married"
    elseif lvgptna == 1 # Living with partner
        mstat[i] = "cohabit"
    else # Set all else to missing
        mstat[i] = missing
    end
end

ESS3_RO[!, :mstat] = mstat

# Ever-divorced
divorce = Vector{Union{Int,Missing}}(undef, nrow(ESS3_RO))

for i in 1:nrow(ESS3_RO)
    local marital = coalesce(ESS3_RO.:marital[i], 99)
    local dvrcdev = coalesce(ESS3_RO.:dvrcdev[i], 99)

    if marital == 5 || dvrcdev == 1
        divorce[i] = 1
    elseif marital == 9 || dvrcdev == 2
        divorce[i] = 0
    else
        divorce[i] = missing
    end
end

ESS3_RO[!, :divorce] = divorce

# 2.4 Select variables ----------------------------------------------------

# Select and rename variables
select!(
    ESS3_RO,
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

Arrow.write("Datasets_tidy/ESS3_RO.arrow", ESS3_RO)