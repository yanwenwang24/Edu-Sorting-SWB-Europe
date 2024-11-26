## ------------------------------------------------------------------------
##
## Script name: 11_tidy_merge.jl
## Purpose: Merge all cleaned ESS datasets
## Author: Yanwen Wang
## Date Created: 2024-11-25
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Merge data -------------------------------------------------------------     

ESS = vcat(
    ESS1,
    ESS2,
    ESS2_IT,
    ESS3,
    ESS3_LV,
    ESS3_RO,
    ESS4,
    ESS4_AT,
    ESS4_LT,
    ESS5,
    ESS5_AT,
    ESS6,
    ESS7,
    ESS8,
    ESS9,
    ESS10
)

@transform!(ESS, :pid = 1:nrow(ESS))
@transform!(ESS, :essround = Int.(:essround))

# 2 Educational sorting indicators ----------------------------------------

ESS = @chain ESS begin
    @transform(
        :edu5_m = [ismissing(g) || ismissing(r) || ismissing(s) ? missing : (g == 0 ? r : s) for (g, r, s) in zip(:female, :edu5_r, :edu5_s)],
        :edu5_f = [ismissing(g) || ismissing(r) || ismissing(s) ? missing : (g == 1 ? r : s) for (g, r, s) in zip(:female, :edu5_r, :edu5_s)]
    )
    @transform(
        :edu4_m = [ismissing(g) || ismissing(r) || ismissing(s) ? missing : (g == 0 ? r : s) for (g, r, s) in zip(:female, :edu4_r, :edu4_s)],
        :edu4_f = [ismissing(g) || ismissing(r) || ismissing(s) ? missing : (g == 1 ? r : s) for (g, r, s) in zip(:female, :edu4_r, :edu4_s)]
    )
    @transform(
        :edu3_m = [ismissing(g) || ismissing(r) || ismissing(s) ? missing : (g == 0 ? r : s) for (g, r, s) in zip(:female, :edu3_r, :edu3_s)],
        :edu3_f = [ismissing(g) || ismissing(r) || ismissing(s) ? missing : (g == 1 ? r : s) for (g, r, s) in zip(:female, :edu3_r, :edu3_s)]
    )
    @transform(
        :heter5 = [ismissing(m) || ismissing(f) ? missing : (m != f ? 1 : 0) for (m, f) in zip(:edu5_m, :edu5_f)],
        :homo5 = [ismissing(m) || ismissing(f) ? missing : (m == f ? 1 : 0) for (m, f) in zip(:edu5_m, :edu5_f)],
        :hyper5 = [ismissing(m) || ismissing(f) ? missing : (m > f ? 1 : 0) for (m, f) in zip(:edu5_m, :edu5_f)],
        :hypo5 = [ismissing(m) || ismissing(f) ? missing : (m < f ? 1 : 0) for (m, f) in zip(:edu5_m, :edu5_f)]
    )
    @transform(
        :heter4 = [ismissing(m) || ismissing(f) ? missing : (m != f ? 1 : 0) for (m, f) in zip(:edu4_m, :edu4_f)],
        :homo4 = [ismissing(m) || ismissing(f) ? missing : (m == f ? 1 : 0) for (m, f) in zip(:edu4_m, :edu4_f)],
        :hyper4 = [ismissing(m) || ismissing(f) ? missing : (m > f ? 1 : 0) for (m, f) in zip(:edu4_m, :edu4_f)],
        :hypo4 = [ismissing(m) || ismissing(f) ? missing : (m < f ? 1 : 0) for (m, f) in zip(:edu4_m, :edu4_f)]
    )
    @transform(
        :heter3 = [ismissing(m) || ismissing(f) ? missing : (m != f ? 1 : 0) for (m, f) in zip(:edu3_m, :edu3_f)],
        :homo3 = [ismissing(m) || ismissing(f) ? missing : (m == f ? 1 : 0) for (m, f) in zip(:edu3_m, :edu3_f)],
        :hyper3 = [ismissing(m) || ismissing(f) ? missing : (m > f ? 1 : 0) for (m, f) in zip(:edu3_m, :edu3_f)],
        :hypo3 = [ismissing(m) || ismissing(f) ? missing : (m < f ? 1 : 0) for (m, f) in zip(:edu3_m, :edu3_f)]
    )
    @transform(
        :edu5_r = categorical(:edu5_r),
        :edu5_s = categorical(:edu5_s),
        :edu5_m = categorical(:edu5_m),
        :edu5_f = categorical(:edu5_f),
        :edu4_r = categorical(:edu4_r),
        :edu4_s = categorical(:edu4_s),
        :edu4_m = categorical(:edu4_m),
        :edu4_f = categorical(:edu4_f),
        :edu3_r = categorical(:edu3_r),
        :edu3_s = categorical(:edu3_s),
        :edu3_m = categorical(:edu3_m),
        :edu3_f = categorical(:edu3_f)
    )
end

# 3 Save data -------------------------------------------------------------

Arrow.write("Datasets_tidy/ESS.arrow", ESS)