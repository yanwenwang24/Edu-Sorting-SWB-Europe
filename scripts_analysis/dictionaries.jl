## ------------------------------------------------------------------------
##
## Script name: dictionaries.jl
## Purpose: Dictionaries for analysis
## Author: Yanwen Wang
## Date Created: 2024-11-26
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# Country and region
region_dict = Dict(
    # Nordic countries
    "DK" => "nordic",    # Denmark
    "FI" => "nordic",    # Finland
    "IS" => "nordic",    # Iceland
    "NO" => "nordic",    # Norway
    "SE" => "nordic",    # Sweden
    
    # Continental countries
    "AT" => "continental",    # Austria
    "BE" => "continental",    # Belgium
    "FR" => "continental",    # France
    "DE" => "continental",    # Germany
    "NL" => "continental",    # Netherlands
    "CH" => "continental",    # Switzerland
    "LU" => "continental",    # Luxembourg
    
    # Southern countries
    "CY" => "southern",    # Cyprus
    "GR" => "southern",    # Greece
    "IT" => "southern",    # Italy
    "PT" => "southern",    # Portugal
    "ES" => "southern",    # Spain
    "TR" => "southern",    # Turkey
    
    # Anglo-Saxon countries
    "IE" => "anglo",    # Ireland
    "GB" => "anglo",    # United Kingdom
    
    # Baltic countries
    "EE" => "baltic",    # Estonia
    "LV" => "baltic",    # Latvia
    "LT" => "baltic",    # Lithuania
    
    # Eastern countries
    "BG" => "eastern",    # Bulgaria
    "CZ" => "eastern",    # Czechia
    "HR" => "eastern",    # Croatia
    "HU" => "eastern",    # Hungary
    "PL" => "eastern",    # Poland
    "RU" => "eastern",    # Russia
    "SK" => "eastern",    # Slovakia
    "SI" => "eastern",    # Slovenia
    "UA" => "eastern",    # Ukraine
    "RO" => "eastern",    # Romania
    "AL" => "eastern",    # Albania
    "XK" => "eastern",    # Kosovo
    "ME" => "eastern",    # Montenegro
    "RS" => "eastern",    # Serbia
    "MK" => "eastern"     # North Macedonia
)