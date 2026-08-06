# ===================================================================
# Carbon capture (linear). Two distinct limits:
#
#  1. PHYSICAL capturable CO2 per route, co2_capturable_X[t] -- the gross CO2 in
#     the capture-amenable streams (coke/PCI/lime for BF; coal/lime for Coal-DRI;
#     NG/coal/lime for NG-DRI). This ~= the route Scope-1 and scales with output.
#     A route can physically capture at most n10_ccs_eta*fc_max of its own base.
#
#  2. DEPLOYMENT (logistics/storage/infrastructure) ceiling -- the binding one.
#     ccs_avail[t] is the exogenous fraction of the sector's capturable CO2 that
#     the CCS build-out (capture modules, pipelines, storage permits) can handle
#     in year t. It is ~0 at first capture (2027) and ramps to 0.50 by 2050 as
#     the system orients toward the tech; this REPLACES the old per-route ramp.
#     The captured amount is the decision, bounded by a single SECTOR-WIDE ceiling
#       sum_X ccs_X[t] <= ccs_avail[t] * sum_X co2_capturable_X[t].
#
# The captured amount ccs_* is the decision variable (linear; no bilinears).
# mip-v3: route outputs are plain crude steel, so the per-tCS EAF coal/lime
# shares apply directly: eaf_coal_in*f_cdri = n7_cs*coaldri_output, etc.
# ===================================================================
param fc_max := 0.9;   # max physical capture rate per stream

# --- physical capturable CO2 base per route (linear in flows) ---
s.t. co2_capturable_bf_def{t in T}:
    co2_capturable_bf[t] =
        coking_coal_in[t] * 0.1116 * 25 + bf_coalpci_in[t] * 0.106 * 26
      + (sinter_lime_in[t] + bf_lime_in[t] + bof_lime_in[t]) * 0.44;        # base for eq84
      # H3 fix: PCI factor 0.106 matches Scope-1 (s_emissions.mod); was 0.113 (over-credited capture).

s.t. co2_capturable_cdri_def{t in T}:
    co2_capturable_cdri[t] =
        coaldri_coal_in[t] * 0.110 * 24 + (n7_cs*coaldri_output[t]) * 0.110 * 24
      + (n7_ls*coaldri_output[t]) * 0.44;                     # base for eq85

s.t. co2_capturable_ngdri_def{t in T}:
    co2_capturable_ngdri[t] =
        ngdri_ng_in[t] * 0.055 * 50 + (n7_cs*ngdri_output[t]) * 0.110 * 24
      + (n7_ls*ngdri_output[t]) * 0.44;                       # base for eq86

# --- per-route physical capture limit (cannot capture more than eta*fc_max of base) ---
s.t. ccs_bf_cap{t in T}:
    ccs_bf[t]    <= n10_ccs_eta * fc_max * co2_capturable_bf[t];             # eq84
s.t. ccs_cdri_cap{t in T}:
    ccs_cdri[t]  <= n10_ccs_eta * fc_max * co2_capturable_cdri[t];           # eq85
s.t. ccs_ngdri_cap{t in T}:
    ccs_ngdri[t] <= n10_ccs_eta * fc_max * co2_capturable_ngdri[t];          # eq86

# --- deployment-readiness fraction (infrastructure/logistics maturity) ---
# 0 before 2027, then linear ramp to phi_2050 = 0.50 at 2050.
param phi_2050 := 0.50;
param ccs_avail{t in T} :=
    if t < 2027 then 0
    else phi_2050 * (t - 2027) / (2050 - 2027);   # 0 at 2027 -> 0.50 at 2050 (linear)

# --- sector-wide deployment ceiling (the binding CCS limit) ---
s.t. ccs_sector_ceiling{t in T}:
    ccs_bf[t] + ccs_cdri[t] + ccs_ngdri[t]
      <= ccs_avail[t] * (co2_capturable_bf[t] + co2_capturable_cdri[t] + co2_capturable_ngdri[t]);

# Total captured CO2
s.t. total_captured_co2{t in T}:
   ccs_bf[t] +ccs_cdri[t] +ccs_ngdri[t]  - total_ccs[t] = 0;           # eq87
 
#Power used in capture (kWh/tCO2), stream-specific (depends on CO2 concentration).
# mip-v3: COMPRESSION + AUXILIARIES only -- regen heat is the explicit steam
# balance below. Grid-powered: cost at ng_cost_power[t], Scope 2 via grid draw.
s.t. power_capture{t in T}:
  ccs_kwh_bf*ccs_bf[t] + ccs_kwh_cdri*ccs_cdri[t] + ccs_kwh_ngdri*ccs_ngdri[t]
  - power_ccs[t] = 0;                                                   # eq88

# --- Solvent-regeneration STEAM balance (mip-v3): stream-specific demand must be
# covered by waste-heat steam (allocated from the WHR pool, o_waste_heat.mod --
# opportunity cost = foregone power) plus the gas-fired backup boiler. Boiler
# fuel is costed in r_cost.mod and its CO2 is EMITTED (added to Scope 1 in
# s_emissions.mod) and NEVER added to the capturable bases above -- capturing
# the capture-boiler's own CO2 is out of scope.
s.t. ccs_steam_balance{t in T}:
  ccs_steam_bf*ccs_bf[t] + ccs_steam_cdri*ccs_cdri[t] + ccs_steam_ngdri*ccs_ngdri[t]
  = ccs_steam_whr[t] + ccs_steam_boiler[t];                             # eq88b
   
   