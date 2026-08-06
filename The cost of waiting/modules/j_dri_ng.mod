# NG DRI
# Linearization: ngdri_output is a primary decision variable; enforced by
# dri_route_split (k_dri_h2.mod).
#
# mip-v3 scrap blending (linear): ngdri_output is CRUDE STEEL from the NG-DRI
# route. Its metallic charge, n7_dri_ratio (1.1 t/tCS), is split between shaft
# DRI (ngdri_dri_out) and blended scrap (ngdri_scrap_in). The scrap FLOW is the
# yearly decision; its share of the charge is banded to [phi_min_ngdri,
# phi_max_ngdri] (0-40%) and the practice shifts at most blend_ramp of the
# charge per year. 2025 is pinned to the observed baseline phi0_ngdri (13%).
# All shaft inputs (pellets/ore/gas/power) scale with the DRI actually produced.

# Metallic charge: DRI + blended scrap = 1.1 t per tCS of route steel
s.t. ngdri_metallic_balance{t in T}:
    ngdri_dri_out[t] + ngdri_scrap_in[t] = n7_dri_ratio * ngdri_output[t];   # eq51

# Blend: 2025 baseline pin, then band + ramp on the scrap flow
s.t. ngdri_scrap_blend0:
    ngdri_scrap_in[first(T)] = phi0_ngdri * n7_dri_ratio * ngdri_output[first(T)];
s.t. ngdri_scrap_blend_max{t in T: t > first(T)}:
    ngdri_scrap_in[t] <= phi_max_ngdri * n7_dri_ratio * ngdri_output[t];
s.t. ngdri_scrap_blend_min{t in T: t > first(T)}:
    ngdri_scrap_in[t] >= phi_min_ngdri * n7_dri_ratio * ngdri_output[t];
s.t. ngdri_scrap_ramp_up{t in T: t > first(T)}:
    ngdri_scrap_in[t] - ngdri_scrap_in[prev(t)] <= blend_ramp * n7_dri_ratio * ngdri_output[t];
s.t. ngdri_scrap_ramp_dn{t in T: t > first(T)}:
    ngdri_scrap_in[prev(t)] - ngdri_scrap_in[t] <= blend_ramp * n7_dri_ratio * ngdri_output[t];

# Power consumption for NG DRI
s.t. ngdri_power_balance{t in T}:
    n5_e_dri * ngdri_dri_out[t] - ngdri_power_in[t] = 0;        # eq52

# Pellet requirement for NG DRI
s.t. ngdri_pellets_balance{t in T}:
    n5_pel_dri * ngdri_dri_out[t] - ngdri_pellets_in[t] = 0;     # eq53

# Lump ore consumption
s.t. ngdri_lumpore_balance{t in T}:
    n5_ore_dri * ngdri_dri_out[t] - ngdri_lumpore_in[t] = 0;    # eq54

# Natural gas consumption
s.t. ngdri_ng_balance{t in T}:
    n5_ng_dri * ngdri_dri_out[t] - ngdri_ng_in[t] = 0;          # eq55
