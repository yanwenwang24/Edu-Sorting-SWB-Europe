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
region_dict = Dict
    # Nordic countries
    "DK" => "Nordic",    # Denmark
    "FI" => "Nordic",    # Finland
    "IS" => "Nordic",    # Iceland
    "NO" => "Nordic",    # Norway
    "SE" => "Nordic",    # Sweden
    
    # Continental countries
    "AT" => "Continental",    # Austria
    "BE" => "Continental",    # Belgium
    "FR" => "Continental",    # France
    "DE" => "Continental",    # Germany
    "NL" => "Continental",    # Netherlands
    "CH" => "Continental",    # Switzerland
    "LU" => "Continental",    # Luxembourg
    
    # Southern countries
    "CY" => "Southern",    # Cyprus
    "GR" => "Southern",    # Greece
    "IT" => "Southern",    # Italy
    "PT" => "Southern",    # Portugal
    "ES" => "Southern",    # Spain
    "TR" => "Southern",    # Turkey
    
    # Anglo-Saxon countries
    "IE" => "Anglo-Saxon",    # Ireland
    "GB" => "Anglo-Saxon",    # United Kingdom
    
    # Baltic countries
    "EE" => "Baltic",    # Estonia
    "LV" => "Baltic",    # Latvia
    "LT" => "Baltic",    # Lithuania
    
    # Eastern countries
    "BG" => "Central & Eastern",    # Bulgaria
    "CZ" => "Central & Eastern",    # Czechia
    "HR" => "Central & Eastern",    # Croatia
    "HU" => "Central & Eastern",    # Hungary
    "PL" => "Central & Eastern",    # Poland
    "RU" => "Central & Eastern",    # Russia
    "SK" => "Central & Eastern",    # Slovakia
    "SI" => "Central & Eastern",    # Slovenia
    "UA" => "Central & Eastern",    # Ukraine
    "RO" => "Central & Eastern",    # Romania
    "AL" => "Central & Eastern",    # Albania
    "XK" => "Central & Eastern",    # Kosovo
    "ME" => "Central & Eastern",    # Montenegro
    "RS" => "Central & Eastern",    # Serbia
    "MK" => "Central & Eastern"     # North Macedonia
