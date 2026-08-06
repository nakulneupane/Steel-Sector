# ============================================================================
# SENSITIVITY DIALS (mip-v3). This file is the scenario cockpit: every axis is
# tweaked HERE by overriding definitions.mod defaults. The 2050 H2 and CCS
# costs are NEVER set directly -- they EMERGE from the dials below (check the
# "POWER SCENARIO" and "LCOH BREAKDOWN" tables in the report output).
#
#   theta_grid  in [0,1] -- India grid outcome (EF + industrial tariff):
#       0 = dirty/expensive: 2050 EF 0.0006 tCO2/kWh, tariff rises to 0.085
#       1 = clean/cheap:     2050 EF 0.0003,           tariff falls to 0.055
#   theta_tech  in [0,1] -- global H2-tech learning (electrolyser + RE capex):
#       0 = expensive H2: 2050 LCOH ~ $3.7/kg   (band $3-4)
#       1 = cheap H2:     2050 LCOH ~ $1.8/kg   (band $1-2)
#       (2025 is always $5/kg -- the lcoh_2025_target calibration anchor.)
#   theta_ccs   in [0,1] -- capture-plant learning (overnight capex decline):
#       0 = expensive CCS: 2050 capture cost ~ $84/tCO2 ex-T&S (band $60-100)
#       1 = cheap CCS:     2050 capture cost ~ $42/tCO2 ex-T&S (band $30-60)
#       (+ ccs_ts_cost $20/t for the all-in; 2025 is always the $125 anchor.
#        The old CCSVAL / n10_ccs_cost_end 2050 anchor is deprecated.)
#
# Uncomment / edit to set the scenario:
let theta_grid := 0.5;    # 1 means clean/mature grid ecosystem
let theta_tech := 0.5;    # 1 means cheap/matured hydrogen ecosystem
let theta_ccs  := 0.5;    # 1 means cheap/matured CCS ecosystem
#
# Other established axes in this file: NG price (n5_cost_NG) & availability
# (n5_ng_cap), H2 start year (ng_h2_start_year), scrap cost/limit/growth
# (ng_cost_scrap, n8_scrap_limit, n8_scrap_rate); plus scenario files for
# coking coal (ccoal_cap) and the emission cap (avg_emi).
# ============================================================================

# ==================================================
# Crude Steel Production
# ==================================================
let base_demand := 152200000;
let growth_rate := 0.05;
param avg_emi   default 1.8;  # cumulative average CO2-intensity CAP, tCO2/tCS (overridable via MC_AVG_EMI)

# ==================================================
# NG DRI
# ==================================================
# Normal price
let {t in T} n5_cost_NG[t] := 10;


# Shock period (2035–2040): only for shock case it is 1.5 times
#let {t in 2035..2040} n5_cost_NG[t] := 22.5;

# ==================================================
# H2 DRI
# ==================================================
# (H2 cost is now the explicit electrolyser + renewable build capex, swept via
#  h2_capex_mult; the old delivered-price ng_cost_h2 was removed.)
let ng_h2_start_year := 2030;
# ==================================================
# Scrap availability (mip-v3: n8_scrap_limit is the TOTAL scrap pool shared by
# the BF-BOF blend, the DRI-EAF blends and dedicated Scrap-EAF; enforced from
# 2026 by scrap_bound -- the pinned 2025 baseline blends sit slightly above it)
# ==================================================
let n8_scrap_rate := 0.06;      # Assumed annual growth rate of scrap
let ng_cost_scrap :=350;        #Assumed scrap cost
let n8_scrap_limit[first(T)] := 37000000;

let {t in T: ord(t) > 1}
    n8_scrap_limit[t] :=
        n8_scrap_limit[prev(t)] * (1 + n8_scrap_rate);

# ==================================================
# Waste Heat Recovery / grid
# ==================================================
# (n9_grid_ef_end is now theta-coupled by default -- 0.0003 at theta_grid = 0.5,
#  see the POWER-TRANSITION SCENARIO block in definitions.mod. A scenario file or
#  driver may still `let n9_grid_ef_end := X;` to override the coupling.)

# ==================================================
# Carbon Capture
# ==================================================
let n10_ccs_cost_start := 125;   # ALL-IN CCS anchor 2025 (capex+O&M+energy+solvent+T&S)
# (n10_ccs_cost_end is DEPRECATED: the 2050 CCS cost now emerges from the
#  theta_ccs capex-learning path -- see the SENSITIVITY DIALS block up top.)


# Reference scale for the mode-1 (linear) electrolyser-capacity slab (ramp_frac * H2_cap
# per year, v_capacity.mod). No longer a flow cap -- the H2 deployment ceiling now lives
# entirely on electrolyser capacity in every mode.
param H2_cap := 1500000;

# Green-H2 availability gate: zero H2-DRI hydrogen before the debut year (a tech-
# availability date, NOT a build-rate cap -- the ramp ceiling is in v_capacity.mod).
s.t. No_H2_Before{t in T: t < ng_h2_start_year}:
    h2dri_h2_in[t] = 0;

# Couple the Gaussian buildout peak to the H2 debut now that the start year is concrete
# (mode 2 only uses it; harmless otherwise). A driver may re-let h2_peak_year afterwards
# to treat the peak as an independent axis.
let h2_peak_year := ng_h2_start_year + 5;


#Natural gas cap (10% of availability of national scale)
#Policy case


#BAU Values
#let n5_ng_cap[2025] := 5348550;
#let n5_ng_cap[2026] := 5417100;
#let n5_ng_cap[2027] := 5568150;
#let n5_ng_cap[2028] := 5794875;
#let n5_ng_cap[2029] := 6105525;
#let n5_ng_cap[2030] := 6263250;
#let n5_ng_cap[2031] := 6426450;
#let n5_ng_cap[2032] := 6758475;
#let n5_ng_cap[2033] := 7023225;
#let n5_ng_cap[2034] := 7182600;
#let n5_ng_cap[2035] := 7439175;
#let n5_ng_cap[2036] := 7611600;
#let n5_ng_cap[2037] := 7790250;
#let n5_ng_cap[2038] := 8039325;
#let n5_ng_cap[2039] := 8101350;
#let n5_ng_cap[2040] := 8187450;
#let n5_ng_cap[2041] := 8385525;
#let n5_ng_cap[2042] := 8550600;
#let n5_ng_cap[2043] := 8842950;
#let n5_ng_cap[2044] := 9033300;
#let n5_ng_cap[2045] := 9186600;
#let n5_ng_cap[2046] := 9607350;
#let n5_ng_cap[2047] := 9884775;
#let n5_ng_cap[2048] := 10197600;
#let n5_ng_cap[2049] := 10385400;
#let n5_ng_cap[2050] := 10662075;

#Shock case

let n5_ng_cap[2025] := 5348550;
let n5_ng_cap[2026] := 5856675;
let n5_ng_cap[2027] := 6343875;
let n5_ng_cap[2028] := 6851550;
let n5_ng_cap[2029] := 7526175;
let n5_ng_cap[2030] := 8293950;
let n5_ng_cap[2031] := 8967150;
let n5_ng_cap[2032] := 9523425;
let n5_ng_cap[2033] := 10172625;
let n5_ng_cap[2034] := 10928175;
let n5_ng_cap[2035] := 7842225;
let n5_ng_cap[2036] := 7999125;
let n5_ng_cap[2037] := 8188200;
let n5_ng_cap[2038] := 8300550;
let n5_ng_cap[2039] := 8411025;
let n5_ng_cap[2040] := 8708775;
let n5_ng_cap[2041] := 11721825;
let n5_ng_cap[2042] := 12549000;
let n5_ng_cap[2043] := 13532700;
let n5_ng_cap[2044] := 14522775;
let n5_ng_cap[2045] := 15491025;
let n5_ng_cap[2046] := 16623450;
let n5_ng_cap[2047] := 17940750;
let n5_ng_cap[2048] := 19201050;
let n5_ng_cap[2049] := 20696025;
let n5_ng_cap[2050] := 21911625;


#let carbon_tax :=200;