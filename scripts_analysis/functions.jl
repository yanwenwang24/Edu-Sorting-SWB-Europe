## ------------------------------------------------------------------------
##
## Script name: functions.jl
## Purpose: Functions for analysis
## Author: Yanwen Wang
## Date Created: 2024-11-26
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# Function for analyzing missing values
function analyze_missing_values(df::DataFrame)
    # Calculate missing values for each column
    n_rows = nrow(df)

    # Create a new DataFrame to store results
    missing_stats = DataFrame(
        variable=names(df),
        n_missing=map(col -> sum(ismissing.(col)), eachcol(df)),
        pct_missing=map(col -> round(100 * sum(ismissing.(col)) / n_rows, digits=2), eachcol(df))
    )

    # Sort by percentage missing in descending order
    sort!(missing_stats, :pct_missing, rev=true)

    # Print summary statistics
    n_complete_cols = sum(missing_stats.n_missing .== 0)
    n_partial_cols = sum(missing_stats.n_missing .> 0)
    n_all_missing = sum(missing_stats.n_missing .== n_rows)

    println("\nMissing Values Summary:")
    println("Total number of observations: ", n_rows)
    println("Number of variables: ", ncol(df))
    println("Complete columns (no missing): ", n_complete_cols)
    println("Columns with missing values: ", n_partial_cols)
    println("Columns with all missing: ", n_all_missing)
    println("\nDetailed missing values by column:")

    return missing_stats
end

# Function for spreading column to dummy variables
function spread_to_dummies(df::DataFrame, col::Symbol;
    prefix::Union{String,Nothing}=nothing,
    drop_original::Bool=false)

    # Get the unique values, excluding missing
    unique_vals = sort(unique(skipmissing(df[!, col])))

    # Create prefix for new column names
    # If no prefix provided, use the original column name
    col_prefix = isnothing(prefix) ? String(col) : prefix

    # Generate new column names
    new_cols = [Symbol(col_prefix, "_", val) for val in unique_vals]

    # Create dummy variables
    dummy_cols = Dict(
        new_col => [ismissing(val) ? missing : (val == unique_vals[i] ? 1 : 0)
                    for val in df[!, col]]
        for (i, new_col) in enumerate(new_cols)
    )

    # Create new DataFrame with dummy columns
    result_df = if drop_original
        select(df, Not(col))
    else
        copy(df)
    end

    # Add dummy columns to result
    for (col_name, values) in dummy_cols
        result_df[!, col_name] = values
    end

    return result_df
end