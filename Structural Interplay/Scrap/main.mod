# Steel-decarbonisation model (pure LP; scrap blending is linear -- flow
# decisions banded/ramped per route, see the SCRAP BLENDING block in
# definitions.mod).
reset;
set T ordered := 2025..2050;
# definitions.mod must precede variables.mod: route-output and capture vars
# carry bounds that reference params (dem) defined in definitions.mod.
include definitions.mod;
include variables.mod;
include parameters.mod;
include modules/a_coke.mod;
include modules/b_sinter.mod;
include modules/c_pellets_bf.mod;
include modules/d_blast_furnace.mod;
include modules/e_bof.mod;
include modules/f_pellets_coaldri.mod;
include modules/g_pellets_ngdri.mod;
include modules/h_pellets_h2dri.mod;
include modules/i_dri_coal.mod;
include modules/j_dri_ng.mod;
include modules/k_dri_h2.mod;
include modules/l_eaf_dri.mod;
include modules/m_scrap_eaf.mod;
include modules/n_steel_balance.mod;
include modules/q_carbon_capture.mod;
include modules/o_waste_heat.mod;
include modules/p_power_balance.mod;
include modules/v_capacity.mod;          # capacity stock + builds
include modules/r_cost.mod;
include modules/s_emissions.mod;
include modules/t_additional_constraints.mod;
# Asset-life lock-in is handled economically by the capacity stock in v_capacity.mod
# (sunk overnight capex + fixed opex), which replaced the former hard-floor u_lockin.

param discount_factor{t in T} :=
    1 / (1 + real_discount_rate)^(ord(t) - 1);
minimize obj:
  # Capex is OVERNIGHT and FULLY SUNK (no residual-life salvage/resale credit):
  # irreversible industrial capital has no resale market. This is consistent with
  # the irreversibility thesis and avoids terminal-year build gaming (a salvage
  # credit would make last-year capacity nearly free and end-load all investment).
    sum {t in T} discount_factor[t] * total_cost[t];

option solver gurobi;
# Linear model (the scrap-blend rules are flow bands/ramps, not fraction
# variables) => pure LP; nonconvex=2 not required.
option gurobi_options 'Threads=10 outlev=1 mipgap=0.002';
option show_stats 1; #Detailed information

solve;
include yreport.mod;


