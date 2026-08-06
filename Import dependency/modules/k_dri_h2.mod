# H2 DRI

# Linearization: linear route split (replaces the old bilinear route-fraction
# products). The coal/NG/H2 route outputs must sum to DRI-EAF steel; the
# optimizer chooses the split directly, and h2dri_output >= 0 enforces the
# implicit f_cdri + f_ngdri <= 1. All outputs are CRUDE STEEL tonnes.
s.t. dri_route_split{t in T}:
    coaldri_output[t] + ngdri_output[t] + h2dri_output[t] - dri_eaf_steel_out[t] = 0;   # eq56

# mip-v3 scrap blending (linear): the H2 route's metallic charge, n7_dri_ratio
# (1.1 t/tCS), is split between shaft DRI (h2dri_dri_out) and blended scrap
# (h2dri_scrap_in); the scrap share of the charge is capped at phi_max_h2dri
# (40%). As a NEW route it has no incumbent blend practice, so no phi_min or
# blend_ramp applies. Pre-debut the route is inert: h2dri_h2_in = 0
# (No_H2_Before) forces h2dri_dri_out = 0, and the 40% cap then forces
# h2dri_output = 0 through the metallic balance.
s.t. h2dri_metallic_balance{t in T}:
    h2dri_dri_out[t] + h2dri_scrap_in[t] = n7_dri_ratio * h2dri_output[t];

s.t. h2dri_scrap_blend_max{t in T}:
    h2dri_scrap_in[t] <= phi_max_h2dri * n7_dri_ratio * h2dri_output[t];

# Power consumption for H2 DRI
s.t. h2dri_power_balance{t in T}:
    n6_e_dri * h2dri_dri_out[t] - h2dri_power_in[t] = 0;         # eq57

# Pellets required for H2 DRI
s.t. h2dri_pellets_balance{t in T}:
    n6_pel_dri * h2dri_dri_out[t] - h2dri_pellets_in[t] = 0;      # eq58

# Lump ore requirement
s.t. h2dri_lumpore_balance{t in T}:
    n6_ore_dri * h2dri_dri_out[t] - h2dri_lumpore_in[t] = 0;     # eq59

# Hydrogen consumption
s.t. h2dri_h2_balance{t in T}:
    n6_h2_dri * h2dri_dri_out[t] - h2dri_h2_in[t] = 0;           # eq60
