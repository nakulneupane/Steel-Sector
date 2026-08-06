# BOF balances 

s.t. bof_power_balance{t in T}:
    n3_e_bof * steel_bof[t] - bof_power_in[t] = 0;      # eq33
    
# mip-v3 scrap blending (linear): the blended-scrap FLOW is the yearly decision;
# its share of the BOF metallic charge is banded to [phi_min_bof, phi_max_bof]
# (5-20%: the converter needs some scrap as coolant; heat balance caps the top)
# and the practice shifts at most blend_ramp of the charge per year. 2025 is
# pinned to the observed baseline phi0_bof (9%). Scrap displaces hot metal 1:1
# (bf_hot_metal_out, d_blast_furnace.mod) and competes for the shared pool
# (scrap_bound, t_additional_constraints.mod).
s.t. bof_scrap_blend0:
    bof_scrap_in[first(T)] = phi0_bof * n3_metallic_bof * steel_bof[first(T)];   # eq34a (2025 baseline)
s.t. bof_scrap_blend_max{t in T: t > first(T)}:
    bof_scrap_in[t] <= phi_max_bof * n3_metallic_bof * steel_bof[t];             # eq34b
s.t. bof_scrap_blend_min{t in T: t > first(T)}:
    bof_scrap_in[t] >= phi_min_bof * n3_metallic_bof * steel_bof[t];             # eq34c
s.t. bof_scrap_ramp_up{t in T: t > first(T)}:
    bof_scrap_in[t] - bof_scrap_in[prev(t)] <=  blend_ramp * n3_metallic_bof * steel_bof[t];   # eq34d
s.t. bof_scrap_ramp_dn{t in T: t > first(T)}:
    bof_scrap_in[prev(t)] - bof_scrap_in[t] <=  blend_ramp * n3_metallic_bof * steel_bof[t];   # eq34e

s.t. bof_lime_balance{t in T}:
    n3_ls_bof * steel_bof[t] - bof_lime_in[t] = 0;      # eq35

s.t. bof_slag_balance{t in T}:
    n3_sl_bof * steel_bof[t] - bof_slag_out[t] = 0;     # eq36

s.t. bof_gas_out{t in T}:
    n3_bofg_bof * ng_bofg_cv * steel_bof[t] - bofgas_out[t] = 0;     # eq37
    
s.t. bof_steel_fraction{t in T}:
    f_bof[t] * dem[t] - steel_bof[t] = 0;                    # eq38  (total_steel pinned to dem[t] by meet_demand => linear)

s.t. bof_cog_balance{t in T}:
    n3_rec_cog * ng_cog_cv * steel_bof[t] - bof_cog_in[t] = 0;       # eq39




    