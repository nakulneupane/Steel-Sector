# EAF-I (DRI-EAF) 

# Fraction of total steel going to EAF
s.t. eaf_steel_fraction{t in T}:
    f_eaf[t] * dem[t] - steel_eaf[t] = 0;                 # eq61  (total_steel pinned to dem[t] by meet_demand => linear)

# Power consumption
s.t. eaf_power_balance{t in T}:
    n7_e_eaf[t] * steel_eaf[t] - eaf_power_in[t] = 0;             # eq62

# Scrap charge in DRI-EAF. mip-v3 blending: total EAF-I scrap is the sum of the
# per-route blended flows (each governed by its constant phi_* fraction in the
# i/j/k modules). eaf_scrap_in feeds the scrap cost (r_cost), the scrap-chain
# capacity (v_capacity) and the availability pool (scrap_bound).
s.t. eaf_scrap_balance{t in T}:
    coaldri_scrap_in[t] + ngdri_scrap_in[t] + h2dri_scrap_in[t] - eaf_scrap_in[t] = 0;   # eq63

# Electrode consumption
s.t. eaf_electrode_balance{t in T}:
    n7_eltrd * steel_eaf[t] - eaf_electrode_in[t] = 0;            # eq64
    
# Lime balance
s.t. eaf_lime_balance{t in T}:
    n7_ls * steel_eaf[t] - eaf_lime_in[t] = 0;                    # eq65

# Coal balance
s.t. eaf_coal_balance{t in T}:
    n7_cs * steel_eaf[t] - eaf_coal_in[t] = 0;                    # eq66

# Slag generation
s.t. eaf_slag_balance{t in T}:
    n7_ss * steel_eaf[t] - eaf_slag_out[t] = 0;                   # eq67

# EAF off-gas
s.t. eaf_gas_out{t in T}:
    n7_eafg * steel_eaf[t] - eafgas_out[t] = 0;                   # eq68
    
# mip-v3: dri_eaf_steel_out = total EAF-I crude steel (the coal/NG/H2 route
# outputs sum to it in dri_route_split); the metallic charge split (DRI vs
# blended scrap) is handled per route in the i/j/k modules, so no scrap
# subtraction here (the old eq69 tonnage netting is gone).
s.t. dri_eaf_steel_relation{t in T}:
    steel_eaf[t] - dri_eaf_steel_out[t] = 0;    # eq69












