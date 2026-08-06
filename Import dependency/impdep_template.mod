# ============================================================================
# IMPORT-DEPENDENCE sweep template.
# Question: how does the decarbonisation pathway change across four import
# regimes -- {coking-coal imports scarce/abundant} x {NG imports scarce/
# abundant} -- crossed with the H2 start year, under a fixed cap of 1.8?
# Regimes use availability scenarios RE-ANCHORED to the model's calibrated
# 2025 coking-coal requirement (~60.5 Mt = 77.6 Mt BF steel x 0.779 t/tCS);
# prices FIXED, so this is a pure quantity-dependence story. Import
# dependence itself is an OUTCOME, measured post-solve:
#   - coking coal: India imports ~90% of its requirement. Regimes are
#     HISTORY-CALIBRATED: domestic blendable supply grows +7.5%/yr in BOTH
#     regimes (FY18-FY25 raw production 40.2 -> 66.5 Mt, applied to the ~6 Mt
#     washed-blendable model basis); imports grow +6.4%/yr (2007-08 -> 2022-23
#     steel-sector trend, 22 -> 56 Mt) in ABUNDANT and are FROZEN at 54.5 Mt
#     in SCARCE (import stagnation, precedent 2019-21).
#     Imports_t = max(0, coking coal used_t - domestic_t).
#   - NG: regimes are the user's national scenarios (10% steel allocation):
#     LoNG = BAU (supply only doubles, to 10.7 Mt, while steel demand grows
#     3.4x); HiNG = POLICY (government targets, ~6x to 32.2 Mt). The central
#     Shock case used elsewhere lies between them. Domestic supply to steel
#     is FLAT at 50% of the 2025 cap
#     (ng_domestic ~ 2.674 Mt/yr -- Indian domestic production is roughly
#     flat; growth is LNG). Imports_t = max(0, NG used_t - ng_domestic).
#   - PCI coal and scrap imports deliberately EXCLUDED from the bill.
#
# SELF-CONTAINED: model copy in THIS folder. impdep.bat substitutes REGLABEL,
# IMPCCOALFILE / IMPNGFILE (scenario includes) and H2YRVAL. Fixed backdrop:
#   avg_emi 1.8, all thetas 0.5, MEDIUM ramp (15 Mt / 6 Mt H2 ref),
#   scrap growth 6%, NG 10 $/MMBtu, coking coal $184/t.
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
let avg_emi := 1.8;
let cap_add_common := 15000000;      # Medium ramp
let h2_ref_cap     := 6000000;
let n8_scrap_rate  := 0.06;
let {t in T: ord(t) > 1}
    n8_scrap_limit[t] := n8_scrap_limit[prev(t)] * (1 + n8_scrap_rate);
let {t in T} n5_cost_NG[t] := 10;

# --- sweep tokens (substituted by impdep.bat) ---
let ng_h2_start_year := H2YRVAL;
let h2_peak_year     := ng_h2_start_year + 5;
# import-regime availability profiles (override the parameters.mod defaults)
include IMPCCOALFILE;
include IMPNGFILE;

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

# STUDY CHOICE: the year-on-year intensity-monotonicity constraint is DROPPED
# here (the cumulative avg_emi cap stays). Under coking-coal scarcity the
# least-cost -- indeed the only feasible -- pathway substitutes toward dirtier
# indigenous coal-DRI, i.e. a TEMPORARY intensity bump before decarbonising;
# with monotonicity enforced every LoCoal cell is infeasible and the study
# degenerates. (Worth one line in the paper: import scarcity of coking coal
# CONFLICTS with monotone decarbonisation.)
drop emission_monotonic;

solve;

# --- post-solve import accounting (undiscounted cumulative, 2025-2050) ---
param ng_domestic    := 0.5 * 5348550;  # flat domestic NG to steel, t/yr (50% of 2025 cap)
param ccoal_domestic{t in T} := 6000000 * 1.075^(t-2025);  # domestic coking coal, +7.5%/yr (FY18-25 CAGR)
param cum_ccoal_bill; param cum_ng_import; param cum_ng_bill;
let cum_ccoal_bill := sum{t in T} max(0, coking_coal_in[t] - ccoal_domestic[t]) * ng_cost_ccoal;
let cum_ng_import  := sum{t in T} max(0, ngdri_ng_in[t] - ng_domestic);
let cum_ng_bill    := sum{t in T} max(0, ngdri_ng_in[t] - ng_domestic) * n5_cost_NG[t]*50;

# --- H2 emission reduction in 2050 (same convention as the other studies) ---
param e_h2_2050; param red_h2_2050;
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

printf "%s,%d,%s,%.0f,%.0f,%.0f,%.0f,%.0f,%.2f,%.4f,%.4f,%.4f,%.4f,%.4f,%.0f,%.0f\n",
    "REGLABEL",
    ng_h2_start_year,
    solve_result,
    cum_ccoal_bill,
    cum_ng_bill,
    cum_ccoal_bill + cum_ng_bill,
    cum_ng_import,
    sum{t in T} total_emissions[t],
    (if (sum{t in T} discount_factor[t]*total_steel[t]) > 0
        then (sum{t in T} discount_factor[t]*total_cost[t])
           / (sum{t in T} discount_factor[t]*total_steel[t]) else 0),
    steel_bof[2050]/total_steel[2050],
    coaldri_output[2050]/total_steel[2050],
    ngdri_output[2050]/total_steel[2050],
    h2dri_output[2050]/total_steel[2050],
    steel_scrap_eaf[2050]/total_steel[2050],
    red_h2_2050,
    total_ccs[2050]
    >> "results/impdep_summary.csv";
printf "IMPDEPRESULT %s h2=%d -> %s (bill %.1f B$)\n",
    "REGLABEL", ng_h2_start_year, solve_result, (cum_ccoal_bill+cum_ng_bill)/1e9;

include yreport.mod;
