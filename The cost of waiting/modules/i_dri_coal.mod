# COAL DRI-EAF/IF
# Linearization: coaldri_output is a primary decision variable; the coal/NG/H2
# split is enforced linearly by dri_route_split (k_dri_h2.mod).
#
# mip-v3 scrap blending (linear): coaldri_output is CRUDE STEEL from the
# coal-DRI/IF route (incl. the induction-furnace secondary sector, which blends
# sponge iron + scrap). Its metallic charge, n7_dri_ratio (1.1 t/tCS), is split
# between shaft DRI (coaldri_dri_out) and blended scrap (coaldri_scrap_in). The
# scrap FLOW is the yearly decision; its share of the charge is banded to
# [phi_min_cdri, phi_max_cdri] (0-40%) and the practice shifts at most
# blend_ramp of the charge per year. 2025 is pinned to the observed baseline
# phi0_cdri (38.2%). All shaft inputs (pellets/ore/coal/power) scale with the
# DRI actually produced.

# Metallic charge: DRI + blended scrap = 1.1 t per tCS of route steel
s.t. coaldri_metallic_balance{t in T}:
    coaldri_dri_out[t] + coaldri_scrap_in[t] = n7_dri_ratio * coaldri_output[t];  # eq46

# Blend: 2025 baseline pin, then band + ramp on the scrap flow
s.t. coaldri_scrap_blend0:
    coaldri_scrap_in[first(T)] = phi0_cdri * n7_dri_ratio * coaldri_output[first(T)];
s.t. coaldri_scrap_blend_max{t in T: t > first(T)}:
    coaldri_scrap_in[t] <= phi_max_cdri * n7_dri_ratio * coaldri_output[t];
s.t. coaldri_scrap_blend_min{t in T: t > first(T)}:
    coaldri_scrap_in[t] >= phi_min_cdri * n7_dri_ratio * coaldri_output[t];
s.t. coaldri_scrap_ramp_up{t in T: t > first(T)}:
    coaldri_scrap_in[t] - coaldri_scrap_in[prev(t)] <= blend_ramp * n7_dri_ratio * coaldri_output[t];
s.t. coaldri_scrap_ramp_dn{t in T: t > first(T)}:
    coaldri_scrap_in[prev(t)] - coaldri_scrap_in[t] <= blend_ramp * n7_dri_ratio * coaldri_output[t];

# Power consumption (Coal DRI shaft + IF secondary share carried in n4_e_dri)
s.t. coaldri_power_balance{t in T}:
    n4_e_dri * coaldri_dri_out[t] - coaldri_power_in[t] = 0;       # eq47

# Pellet requirement for Coal DRI
s.t. coaldri_pellets_balance{t in T}:
    n4_pel_dri * coaldri_dri_out[t] - coaldri_pellets_in[t] = 0;      # eq48

# Lump ore requirement (Coal DRI)
s.t. coaldri_lumpore_balance{t in T}:
    n4_ore_dri * coaldri_dri_out[t] - coaldri_lumpore_in[t] = 0;   # eq49

# Coal consumption in Coal DRI
s.t. coaldri_coal_balance{t in T}:
    n4_c_dri * coaldri_dri_out[t] - coaldri_coal_in[t] = 0;        # eq50
