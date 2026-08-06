# ============================================================================
# SCRAP-GROWTH sweep template ("Whom does scrap eat?").
# Question: as scrap availability growth runs 0-10%/yr, does scrap take the
# 2050 abatement share from HYDROGEN or from CCS? Tracked by the driver index
# D = red_H2/(red_H2 + red_CCS), with emission caps 1.6/1.8/2.0 as the lines.
#
# SELF-CONTAINED: uses the model copy in THIS folder (Plots/Scrap). The driver
# scrap.bat runs AMPL from this folder, substituting SCRAPVAL (n8_scrap_rate)
# and EFVAL (avg_emi). Fixed backdrop (set below, overriding parameters.mod):
#   H2 start 2030 (peak 2035), grid EF end 0.0005 (tariff stays on theta_grid),
#   MEDIUM ramp (cap_add_common 15 Mt, h2_ref_cap 6 Mt -> 1.5 Mt-H2/yr peak),
#   NG 10 $/MMBtu, theta_tech = theta_grid = theta_ccs = 0.5.
# ============================================================================
reset;
set T ordered := 2025..2050;

include definitions.mod;
include variables.mod;
include parameters.mod;

# --- fixed study backdrop ---
let theta_tech := 0.5;
let theta_grid := 0.5;
let theta_ccs  := 0.5;
let ng_h2_start_year := 2030;
let h2_peak_year     := 2035;
let n9_grid_ef_end   := 0.0005;      # explicit EF (wins over the theta_grid default)
let cap_add_common   := 15000000;    # Medium ramp
let h2_ref_cap       := 6000000;     # Medium H2 envelope (peak 1.5 Mt-H2/yr)
let {t in T} n5_cost_NG[t] := 10;

# --- sweep tokens (substituted by scrap.bat) ---
let avg_emi       := EFVAL;
let n8_scrap_rate := SCRAPVAL;
# re-derive the scrap-availability recursion from the swept growth rate
let {t in T: ord(t) > 1}
    n8_scrap_limit[t] := n8_scrap_limit[prev(t)] * (1 + n8_scrap_rate);

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

# --- Post-solve: 2050 emission reduction attributable to H2 (average-
# displacement convention, same-run; gross pre-capture intensities keep it
# additive with red_ccs = captured CO2 -- same definitions as the H2_Delay
# study, so D is comparable across studies).
param e_h2_2050;
param red_h2_2050;
let e_h2_2050 :=
    scope1_h2dri[2050]
  + n9_grid_ef[2050] * ( h2dri_power_in[2050] + pellets_power_h2dri[2050]
      + (if dri_eaf_steel_out[2050] > 0
         then h2dri_output[2050]/dri_eaf_steel_out[2050] else 0) * eaf_power_in[2050] );
let red_h2_2050 :=
    if h2dri_output[2050] > 1 and total_steel[2050] > h2dri_output[2050]
    then h2dri_output[2050]
         * (scope1_emissions[2050] + scope2_emissions[2050] - e_h2_2050)
         / (total_steel[2050] - h2dri_output[2050])
         - e_h2_2050
    else 0;

# --- summary line -> results/scrap_summary.csv (header written by scrap.bat).
# Also records total scrap USE in 2050 and the 2050 scrap limit, so the plot
# can show where availability actually binds.
printf "%.2f,%.2f,%s,%.0f,%.0f,%.0f,%.2f,%.0f,%.0f,%.4f\n",
    avg_emi,
    n8_scrap_rate,
    solve_result,
    cap_h2dri[2050],
    total_ccs[2050],
    red_h2_2050,
    (if (sum{t in T} discount_factor[t]*total_steel[t]) > 0
        then (sum{t in T} discount_factor[t]*total_cost[t])
           / (sum{t in T} discount_factor[t]*total_steel[t]) else 0),
    bof_scrap_in[2050] + eaf_scrap_in[2050] + scrap_eaf_scrap_in[2050],
    n8_scrap_limit[2050],
    (if steel_scrap_eaf[2050] > 0 and total_steel[2050] > 0
        then steel_scrap_eaf[2050]/total_steel[2050] else 0)
    >> "results/scrap_summary.csv";
printf "SCRAPRESULT EF=%.2f scrap=%.2f -> %s\n", avg_emi, n8_scrap_rate, solve_result;

include yreport.mod;
