# ============================================================================
# GRID-OFFSET REQUIREMENT sweep template (mip-v3).
# Question: for each (H2 start year x scrap growth rate) combination, how clean
# must the 2050 grid get (n9_grid_ef_end) for the cumulative-average emission
# cap avg_emi (1.8 tCO2/tCS, set in parameters.mod) to remain FEASIBLE?
# The driver grid.bat substitutes the tokens H2ENDVAL / SCRAPVAL / GRIDVAL and
# runs one instance per combination; gridresult.mod appends one CSV line per
# run to results/grid_summary.csv (solve_result column flags infeasibility).
#
# NOTE: the token lets come AFTER include parameters.mod -- parameters.mod
# itself lets ng_h2_start_year, n8_scrap_rate and the scrap-limit recursion,
# so earlier overrides would be silently clobbered (same ordering pattern as
# template.mod).
#
# COUPLED GRID (mip-v3): grid EF and the industrial tariff are NOT independent
# -- theta_grid moves them together. So GRIDVAL (the target 2050 EF) is
# INVERTED into theta_grid, and BOTH paths follow:
#     theta_grid = (GRIDVAL - ef_slow)/(ef_fast - ef_slow)
#     => n9_grid_ef_end = GRIDVAL exactly (linear map), tariff end follows.
# EF values outside [grid_ef_end_fast, grid_ef_end_slow] extrapolate theta
# beyond [0,1] on the same line: EF 0 -> theta 2.0 -> 2050 tariff $0.025;
# EF 0.00085 -> theta -0.83 -> $0.11 (grid stagnation with rising tariffs).
# All other dials (theta_tech, theta_ccs, NG, coking coal, ...) keep their
# parameters.mod scenario values.
# ============================================================================
reset;
set T ordered := 2025..2050;

include definitions.mod;
include variables.mod;
include parameters.mod;

# --- sweep tokens (substituted by grid.bat) ---
let ng_h2_start_year := H2ENDVAL;
let n8_scrap_rate    := SCRAPVAL;
# GRIDVAL is a 2050 EF target: invert it into theta_grid so the EF end lands
# on GRIDVAL exactly AND the tariff path moves consistently with it.
let theta_grid := (GRIDVAL - grid_ef_end_slow)/(grid_ef_end_fast - grid_ef_end_slow);

# Re-derive everything downstream of the overridden dials:
# scrap availability recursion (depends on n8_scrap_rate)
let {t in T: ord(t) > 1}
    n8_scrap_limit[t] := n8_scrap_limit[prev(t)] * (1 + n8_scrap_rate);
# Gaussian electrolyser-buildout peak re-coupled to the (now final) H2 debut
let h2_peak_year := ng_h2_start_year + 5;

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
include modules/v_capacity.mod;
include modules/r_cost.mod;
include modules/s_emissions.mod;
include modules/t_additional_constraints.mod;

param discount_factor{t in T} :=
    1 / (1 + real_discount_rate)^(ord(t) - 1);

minimize obj:
    sum {t in T} discount_factor[t] * total_cost[t];

option solver gurobi;
option gurobi_options 'Threads=10 TimeLimit=300 mipgap=0.002';

solve;

# Machine-readable summary line + full human report. On infeasible runs the
# report prints last-iterate garbage -- filter the CSV on solve_result.
include Plots/Grid/gridresult.mod;
include yreport.mod;
