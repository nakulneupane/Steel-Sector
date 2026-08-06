# ============================================================================
# Monte-Carlo / sweep template for the linearized (MILP) steel model.
#
# The MC driver (monte_carlo.py) and the run_scripts substitute the tokens
#   NGVAL  H2CAPXVAL  H2YEARVAL  CCSVAL  SCRAPVAL  NGAVAILFILE
# (H2CAPXVAL is the green-H2 supply-chain capex multiplier; it replaced the old
#  H2ENDVAL delivered-price axis when H2 capital was split into explicit builds.)
# then solve one instance per draw. Mirrors main.mod but parameterized and with
# the human-readable report includes left for the driver to strip.
#
# Include order: definitions -> variables -> parameters (route/capture variable
# bounds reference params from definitions.mod).
# ============================================================================
reset;
set T ordered := 2025..2050;

include definitions.mod;
include variables.mod;
include parameters.mod;

# --- sampled inputs (token substitution by the driver) ---
let {t in T} n5_cost_NG[t] := NGVAL;
let h2_capex_mult := H2CAPXVAL;
let ng_h2_start_year := H2YEARVAL;
# Re-couple the mode-2 Gaussian peak to the (now-final) H2 debut: peak = start + 5.
# parameters.mod set this earlier from the default start year, before this override; without
# re-coupling, a delayed H2 start strands the electrolyser peak before the flow gate, so
# electrolysers build up idle and switch on at once. A driver (MC H2PEAK) may re-let it after.
let h2_peak_year := ng_h2_start_year + 5;
let n10_ccs_cost_end := CCSVAL;
let avg_emi := AVGEMIVAL;
let ramp_frac := RAMPVAL;

# Scrap-availability regime (starved/modest/abundant): base cap + growth.
# Mirrors the NG-availability scenario mechanism below.
include SCRAPREGIMEFILE;

# NG-availability scenario profile (overrides n5_ng_cap set in parameters.mod)
include NGAVAILFILE;

# Coking-coal availability scenario profile (overrides ccoal_cap set in definitions.mod)
include CCOALFILE;

# Grid emission-factor scenario (overrides n9_grid_ef defined in definitions.mod)
include GRIDEFFILE;

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
  # Overnight, fully sunk capex (no salvage/resale credit) -- see main.mod.
    sum {t in T} discount_factor[t] * total_cost[t];

option solver gurobi;
# Linear model (the scrap-blend rules are flow bands/ramps, not fraction
# variables) => pure LP; nonconvex=2 not required.
option gurobi_options 'Threads=5 TimeLimit=600 mipgap=0.002';

solve;

include yreport.mod;
