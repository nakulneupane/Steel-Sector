# ============================================================================
# Capacity-expansion framework  (branch: capex-opex-framework)
# ----------------------------------------------------------------------------
# Replaces the LCOE-style per-tonne capital charge (n*_capex * production) with
# a real capacity stock:
#   - capacity per route is built (build_X) and bounds production (prod <= cap),
#   - CAPEX is OVERNIGHT, charged on the build in the year it is made (sunk;
#     never refunded by idling),  see capex_cost_def in r_cost.mod,
#   - FIXED OPEX is charged on installed capacity each year (fom_*),
#   - the 2025 incumbent fleet (legacy_X) is a non-increasing stock under a
#     linearly declining ceiling that reaches 0 in 2050 (gentle ~4%/yr phase-out;
#     optimizer may retire FASTER under decarbonisation pressure, never slower).
#
# This module SUPERSEDES u_lockin.mod: a build commits capex + fixed opex for the
# asset life, which discourages build-then-strand economically rather than via a
# forced production floor.
#
# Capacity is tracked on each route's primary OUTPUT variable (the same five the
# old lock-in proxy used).  mip-v3: every route output -- including the DRI routes
# (coaldri_output, ngdri_output, h2dri_output) -- is plain crude steel; the old
# 0.9*steel_eaf crude-steel-equivalent basis is gone.
# ============================================================================

# --- build (capacity added in year t) ---
var build_bof   {T} >= 0;
var build_cdri  {T} >= 0;
var build_ngdri {T} >= 0;
var build_h2dri {T} >= 0;
var build_scrap {T} >= 0;

# --- surviving incumbent (2025) fleet ---
var legacy_bof   {T} >= 0;
var legacy_cdri  {T} >= 0;
var legacy_ngdri {T} >= 0;
var legacy_h2dri {T} >= 0;
var legacy_scrap {T} >= 0;

# --- total installed capacity ---
var cap_bof   {T} >= 0;
var cap_cdri  {T} >= 0;
var cap_ngdri {T} >= 0;
var cap_h2dri {T} >= 0;
var cap_scrap {T} >= 0;

# --- annual cost pieces fed to total_cost_def (r_cost.mod) ---
var capex_cost   {T} >= 0;   # overnight capex booked on this year's builds
var fixopex_cost {T} >= 0;   # fixed O&M on installed capacity

# --- Feedstock / fuel SUPPLY-CHAIN capacity (one rule, different baselines) ---
# Every input obeys the SAME treatment: the established supply network is absorbed
# in the delivered commodity price, and SUNK overnight capex is charged only on
# capacity GROWTH above the 2025 baseline. The routes differ only in their baseline:
#   - scrap:  partial baseline -> capex on growth in furnace-ready processing
#             (shredding/sorting/purification); ocapex_scrapchain default 100.
#   - coal / NG: mature networks, no must-build growth -> ocapex_*chain default 0,
#             so by default all their capital stays in the delivered price (no
#             behaviour change). Non-zero values turn on supply-growth capex.
#   - green H2 (electrolyser + renewable, below): zero baseline -> essentially all
#             capital is an explicit build.
# All chains are monotone -> once built, supply capacity cannot be un-built (sunk).
var scrapchain_cap   {T} >= 0;   # scrap-handling capacity (t scrap/yr)
var build_scrapchain {T} >= 0;   # capacity added this year (t scrap/yr)
var coalchain_cap    {T} >= 0;   # coal supply capacity (t coal/yr, all coal types)
var build_coalchain  {T} >= 0;
var ngchain_cap      {T} >= 0;   # natural-gas supply capacity (t NG/yr)
var build_ngchain    {T} >= 0;

# --- Green-H2 supply chain: electrolyser + dedicated renewable stocks (see the
# detailed block further down). Declared here, BEFORE capex_cost_def/fixopex_cost_def
# reference them, so there is no forward reference (AMPL's CLI tolerates one but
# amplpy's parser does not). ---
var build_h2elec {T} >= 0;   # electrolyser capacity added (t-H2/yr)
var cap_h2elec   {T} >= 0;   # installed electrolyser capacity (t-H2/yr)
var build_h2re   {T} >= 0;   # dedicated renewable capacity added (kW)
var cap_h2re     {T} >= 0;   # installed dedicated renewable capacity (kW)

# ----------------------------------------------------------------------------
# Capacity stock:  cap = surviving legacy + builds still within their life L.
# A build in year j contributes until year j+L-1, then retires automatically.
# ----------------------------------------------------------------------------
s.t. cap_def_bof{t in T}:
    cap_bof[t] = legacy_bof[t]
      + sum{j in T: ord(j) <= ord(t) and ord(j) >= ord(t)-life_bof+1}   build_bof[j];
s.t. cap_def_cdri{t in T}:
    cap_cdri[t] = legacy_cdri[t]
      + sum{j in T: ord(j) <= ord(t) and ord(j) >= ord(t)-life_cdri+1}  build_cdri[j];
s.t. cap_def_ngdri{t in T}:
    cap_ngdri[t] = legacy_ngdri[t]
      + sum{j in T: ord(j) <= ord(t) and ord(j) >= ord(t)-life_ngdri+1} build_ngdri[j];
s.t. cap_def_h2dri{t in T}:
    cap_h2dri[t] = legacy_h2dri[t]
      + sum{j in T: ord(j) <= ord(t) and ord(j) >= ord(t)-life_h2dri+1} build_h2dri[j];
s.t. cap_def_scrap{t in T}:
    cap_scrap[t] = legacy_scrap[t]
      + sum{j in T: ord(j) <= ord(t) and ord(j) >= ord(t)-life_scrap+1} build_scrap[j];

# ----------------------------------------------------------------------------
# Legacy retirement: non-increasing, under a linearly declining ceiling that
# hits 0 in 2050.  Optimizer may sit below the ceiling (retire faster).
# ----------------------------------------------------------------------------
s.t. legacy_ceil_bof  {t in T}: legacy_bof[t]   <= cap0_bof   * (2050 - t)/25;
s.t. legacy_ceil_cdri {t in T}: legacy_cdri[t]  <= cap0_cdri  * (2050 - t)/25;
s.t. legacy_ceil_ngdri{t in T}: legacy_ngdri[t] <= cap0_ngdri * (2050 - t)/25;
s.t. legacy_ceil_h2dri{t in T}: legacy_h2dri[t] <= cap0_h2dri * (2050 - t)/25;
s.t. legacy_ceil_scrap{t in T}: legacy_scrap[t] <= cap0_scrap * (2050 - t)/25;

s.t. legacy_noninc_bof  {t in T: ord(t)>1}: legacy_bof[t]   <= legacy_bof[prev(t)];
s.t. legacy_noninc_cdri {t in T: ord(t)>1}: legacy_cdri[t]  <= legacy_cdri[prev(t)];
s.t. legacy_noninc_ngdri{t in T: ord(t)>1}: legacy_ngdri[t] <= legacy_ngdri[prev(t)];
s.t. legacy_noninc_h2dri{t in T: ord(t)>1}: legacy_h2dri[t] <= legacy_h2dri[prev(t)];
s.t. legacy_noninc_scrap{t in T: ord(t)>1}: legacy_scrap[t] <= legacy_scrap[prev(t)];

# --- pin the 2025 incumbent stock to the seed: the fleet physically exists, so
#     2025 capacity = seed (production runs below it; idle capacity pays fixed opex).
s.t. legacy_init_bof:   legacy_bof[first(T)]   = cap0_bof;
s.t. legacy_init_cdri:  legacy_cdri[first(T)]  = cap0_cdri;
s.t. legacy_init_ngdri: legacy_ngdri[first(T)] = cap0_ngdri;
s.t. legacy_init_h2dri: legacy_h2dri[first(T)] = cap0_h2dri;
s.t. legacy_init_scrap: legacy_scrap[first(T)] = cap0_scrap;

# ----------------------------------------------------------------------------
# Production bounded by installed capacity, derated to util_max (95%): annual
# maintenance, raw-material shocks and unplanned outages make 100% utilisation
# unachievable. Mode 0 (no-limits counterfactual) relaxes the derating to 1,
# same value-switch idiom as the ramp ceilings and utilisation floors.
# ----------------------------------------------------------------------------
s.t. cap_lim_bof  {t in T}: steel_bof[t]       <= (if h2_ramp_mode = 0 then 1 else util_max) * cap_bof[t];
s.t. cap_lim_cdri {t in T}: coaldri_output[t]  <= (if h2_ramp_mode = 0 then 1 else util_max) * cap_cdri[t];
s.t. cap_lim_ngdri{t in T}: ngdri_output[t]    <= (if h2_ramp_mode = 0 then 1 else util_max) * cap_ngdri[t];
s.t. cap_lim_h2dri{t in T}: h2dri_output[t]    <= (if h2_ramp_mode = 0 then 1 else util_max) * cap_h2dri[t];
s.t. cap_lim_scrap{t in T}: steel_scrap_eaf[t] <= (if h2_ramp_mode = 0 then 1 else util_max) * cap_scrap[t];

# ----------------------------------------------------------------------------
# Per-route capacity-addition ceiling (replaces the old production ramp).
# mip-v3: ONE COMMON absolute slab, cap_add_common (10 Mt crude steel/yr), shared
# by all four major routes -- the former tech-specific cap_add_frac_X * cap0_X
# slabs produced inconsistent effective limits with no clear justification.
# Limits the PHYSICAL build rate, NOT dispatch. H2-DRI is governed instead by the
# electrolyser envelope below. Same constraint in every mode; only the ceiling
# VALUE switches: mode 0 = H2_BIGM (no limit), modes 1 & 2 = the common slab.
# ----------------------------------------------------------------------------
s.t. cap_add_bof  {t in T: t > first(T)}: build_bof[t]   <= (if h2_ramp_mode = 0 then H2_BIGM else cap_add_common);
s.t. cap_add_cdri {t in T: t > first(T)}: build_cdri[t]  <= (if h2_ramp_mode = 0 then H2_BIGM else cap_add_common);
s.t. cap_add_ngdri{t in T: t > first(T)}: build_ngdri[t] <= (if h2_ramp_mode = 0 then H2_BIGM else cap_add_common);
s.t. cap_add_scrap{t in T: t > first(T)}: build_scrap[t] <= (if h2_ramp_mode = 0 then H2_BIGM else cap_add_common);

# 2025 is the calibrated base year: capacity = the observed seed (legacy = cap0), so there
# are no NEW route builds in 2025. The cap_add ceilings above start at t>first(T), which
# otherwise leaves build_X[2025] unconstrained -- the optimiser then pre-builds idle capacity
# in the base year to dodge the per-route addition ceiling (visible as NG-DRI sitting above
# its envelope before ~2040). Pin the first-year builds to zero; new capacity begins in 2026.
s.t. cap_add_bof0:   build_bof[first(T)]   = 0;
s.t. cap_add_cdri0:  build_cdri[first(T)]  = 0;
s.t. cap_add_ngdri0: build_ngdri[first(T)] = 0;
s.t. cap_add_scrap0: build_scrap[first(T)] = 0;

# ----------------------------------------------------------------------------
# Minimum capacity utilisation (private-player discipline): production >= util_min
# * installed capacity, so the idle gap is capped at (1-util_min). The optimiser
# satisfies it by shedding idle legacy faster and not stranding built vintages -- a
# plant, once built, is run rather than mothballed. Exempt at first(T) (2025): the
# inherited fleet is calibrated to observed shares and runs below 75% (e.g. BF-BOF
# ~64%). H2-DRI is auto-0 before its start year (No_H2_Before forces output=0, so
# cap_h2dri is held at 0 there too). Mode 0 (no limits) is the no-discipline
# counterfactual: the floor coefficient switches to 0, so the constraint is present
# in every mode but inert in mode 0 (same value-switch idiom as the ramp ceilings).
# ----------------------------------------------------------------------------
s.t. min_util_bof  {t in T: t > first(T)}: steel_bof[t]       >= (if h2_ramp_mode = 0 then 0 else util_min_bof)   * cap_bof[t];
s.t. min_util_cdri {t in T: t > first(T)}: coaldri_output[t]  >= (if h2_ramp_mode = 0 then 0 else util_min_cdri)  * cap_cdri[t];
s.t. min_util_ngdri{t in T: t > first(T)}: ngdri_output[t]    >= (if h2_ramp_mode = 0 then 0 else util_min_ngdri) * cap_ngdri[t];
s.t. min_util_h2dri{t in T: t > first(T)}: h2dri_output[t]    >= (if h2_ramp_mode = 0 then 0 else util_min_h2dri) * cap_h2dri[t];
s.t. min_util_scrap{t in T: t > first(T)}: steel_scrap_eaf[t] >= (if h2_ramp_mode = 0 then 0 else util_min_scrap) * cap_scrap[t];

# ----------------------------------------------------------------------------
# Cost pieces (consumed by total_cost_def in r_cost.mod).
#   capex_cost   = overnight capex on this year's builds, charged in FULL in the
#                  build year and fully sunk (no residual-life salvage credit; see
#                  the objective note in main.mod).
#   fixopex_cost = fixed O&M (labour + maintenance, a flat per-capacity rate -- NOT
#                  a fraction of capex) on installed capacity.
# ----------------------------------------------------------------------------
# scrap-chain capacity must cover total scrap throughput (all 3 streams: scrap-EAF
# charge + BOF scrap + DRI-EAF scrap charge). 2025 capacity is pinned to that
# year's throughput (legacy, free); growth above it pays sunk capex. Monotone.
s.t. scrapchain_legacy{t in T: ord(t) = 1}:
    scrapchain_cap[t] = bof_scrap_in[t] + eaf_scrap_in[t] + scrap_eaf_scrap_in[t];
s.t. scrapchain_cover{t in T: ord(t) > 1}:
    scrapchain_cap[t] >= bof_scrap_in[t] + eaf_scrap_in[t] + scrap_eaf_scrap_in[t];
s.t. scrapchain_mono{t in T: ord(t) > 1}:
    scrapchain_cap[t] >= scrapchain_cap[prev(t)];
s.t. scrapchain_build_def{t in T: ord(t) > 1}:
    build_scrapchain[t] >= scrapchain_cap[t] - scrapchain_cap[prev(t)];

# coal supply chain: covers ALL coal throughput (coking + PCI + DRI + EAF coal).
# 2025 throughput is the free baseline; growth above it pays ocapex_coalchain
# (default 0 -> mature network, capital stays in the delivered coal prices).
s.t. coalchain_legacy{t in T: ord(t) = 1}:
    coalchain_cap[t] = coking_coal_in[t] + bf_coalpci_in[t] + coaldri_coal_in[t]
                     + eaf_coal_in[t] + scrap_eaf_coal_in[t];
s.t. coalchain_cover{t in T: ord(t) > 1}:
    coalchain_cap[t] >= coking_coal_in[t] + bf_coalpci_in[t] + coaldri_coal_in[t]
                      + eaf_coal_in[t] + scrap_eaf_coal_in[t];
s.t. coalchain_mono{t in T: ord(t) > 1}:
    coalchain_cap[t] >= coalchain_cap[prev(t)];
s.t. coalchain_build_def{t in T: ord(t) > 1}:
    build_coalchain[t] >= coalchain_cap[t] - coalchain_cap[prev(t)];

# natural-gas supply chain: covers NG-DRI gas use. Same structure; ocapex_ngchain
# default 0 (mature pipeline/import network, capital in the delivered NG price).
s.t. ngchain_legacy{t in T: ord(t) = 1}:
    ngchain_cap[t] = ngdri_ng_in[t];
s.t. ngchain_cover{t in T: ord(t) > 1}:
    ngchain_cap[t] >= ngdri_ng_in[t];
s.t. ngchain_mono{t in T: ord(t) > 1}:
    ngchain_cap[t] >= ngchain_cap[prev(t)];
s.t. ngchain_build_def{t in T: ord(t) > 1}:
    build_ngchain[t] >= ngchain_cap[t] - ngchain_cap[prev(t)];

s.t. capex_cost_def{t in T}:
    capex_cost[t] =
      sunk * (   ocapex_bof      * build_bof[t]          # sunk: overnight capex on builds
               + ocapex_cdri     * build_cdri[t]
               + ocapex_ngdri    * build_ngdri[t]
               + ocapex_h2dri[t] * build_h2dri[t]
               + ocapex_scrap    * build_scrap[t]
               + ocapex_scrapchain * build_scrapchain[t]   # scrap collection+yard expansion
               + ocapex_coalchain * build_coalchain[t]     # coal supply-network growth (default 0)
               + ocapex_ngchain   * build_ngchain[t]       # NG supply-network growth  (default 0)
               + ocapex_h2elec[t] * build_h2elec[t]        # green-H2: electrolyser builds
               + ocapex_h2re[t]   * build_h2re[t] )        # green-H2: dedicated renewable builds
    + (1-sunk) * ( acapex_bof    * steel_bof[t]          # not sunk: annualized capex on production
               + acapex_cdri     * coaldri_output[t]
               + acapex_ngdri    * ngdri_output[t]
               + acapex_h2dri[t] * h2dri_output[t]
               + acapex_scrap    * steel_scrap_eaf[t]
               + acapex_h2elec[t] * h2dri_h2_in[t]
               + acapex_h2re[t]   * h2dri_h2_in[t] * h2_kwh_per_t/(8760*re_cf) );

# Fixed opex (labour + maintenance) on installed capacity, crude-steel basis.
# mip-v3: all route capacities are plain crude-steel tonnes, so the per-tCS
# fixed-opex rate applies directly (no basis conversion).
s.t. fixopex_cost_def{t in T}:
    fixopex_cost[t] =
      sunk * (   fopex_bof   * cap_bof[t]                          # sunk: fixed opex on capacity
               + fopex_cdri  * cap_cdri[t]
               + fopex_ngdri * cap_ngdri[t]
               + fopex_h2dri * cap_h2dri[t]
               + fopex_scrap * cap_scrap[t]
               + fopex_h2elec * cap_h2elec[t]                      # green-H2: electrolyser fixed O&M
               + fopex_h2re   * cap_h2re[t] )                      # green-H2: renewable fixed O&M
    + (1-sunk) * ( fopex_bof   * steel_bof[t]                      # not sunk: fixed opex on production
               + fopex_cdri  * coaldri_output[t]
               + fopex_ngdri * ngdri_output[t]
               + fopex_h2dri * h2dri_output[t]
               + fopex_scrap * steel_scrap_eaf[t]
               + fopex_h2elec * h2dri_h2_in[t]
               + fopex_h2re   * h2dri_h2_in[t] * h2_kwh_per_t/(8760*re_cf) );

# ============================================================================
# CCS retrofit capacity (sunk capex; legacy = 0, no CCS in 2025). Mirrors the
# route framework: capture <= installed capture capacity, built via build_ccs_X
# over a life_ccs-year retrofit life. Cost lives in r_cost.mod (cost_ccs_def);
# the physical-capture and deployment-ceiling limits stay in q_carbon_capture.mod.
# ============================================================================
var build_ccs_bf   {T} >= 0;
var build_ccs_cdri {T} >= 0;
var build_ccs_ngdri{T} >= 0;
var ccs_cap_bf     {T} >= 0;
var ccs_cap_cdri   {T} >= 0;
var ccs_cap_ngdri  {T} >= 0;

s.t. ccs_cap_def_bf{t in T}:
    ccs_cap_bf[t]    = sum{j in T: ord(j)<=ord(t) and ord(j)>=ord(t)-life_ccs+1} build_ccs_bf[j];
s.t. ccs_cap_def_cdri{t in T}:
    ccs_cap_cdri[t]  = sum{j in T: ord(j)<=ord(t) and ord(j)>=ord(t)-life_ccs+1} build_ccs_cdri[j];
s.t. ccs_cap_def_ngdri{t in T}:
    ccs_cap_ngdri[t] = sum{j in T: ord(j)<=ord(t) and ord(j)>=ord(t)-life_ccs+1} build_ccs_ngdri[j];

s.t. ccs_caplim_bf{t in T}:    ccs_bf[t]    <= ccs_cap_bf[t];
s.t. ccs_caplim_cdri{t in T}:  ccs_cdri[t]  <= ccs_cap_cdri[t];
s.t. ccs_caplim_ngdri{t in T}: ccs_ngdri[t] <= ccs_cap_ngdri[t];

# ============================================================================
# Green-H2 supply chain (sunk capex; legacy = 0, negligible green H2 in 2025).
# Two stacked capacity stocks, each built and vintaged like a route:
#   - electrolysers   cap_h2elec [t-H2/yr]  must cover total H2 use (DRI + BF),
#   - dedicated renewables cap_h2re [kW] must generate enough to power them.
# Capex/opex parameters live in definitions.mod; the cost terms are folded into
# capex_cost_def / fixopex_cost_def below. The H2 *price* term in r_cost.mod is
# reduced to the residual variable opex h2_opex (the capital lives here now).
# Renewable power is dedicated/behind-the-meter: it is sized to cover the
# electrolyser load and is therefore NOT added to the grid power balance, which
# keeps H2 green (no grid-EF Scope-2 on electrolysis).
# (The build_*/cap_* variables are declared up top with the other supply-chain
# stocks, so capex_cost_def/fixopex_cost_def can reference them without a forward ref.)
# ============================================================================
s.t. cap_def_h2elec{t in T}:
    cap_h2elec[t] = sum{j in T: ord(j)<=ord(t) and ord(j)>=ord(t)-life_h2elec+1} build_h2elec[j];
s.t. cap_def_h2re{t in T}:
    cap_h2re[t]   = sum{j in T: ord(j)<=ord(t) and ord(j)>=ord(t)-life_re+1}     build_h2re[j];

# No electrolyser (or dedicated renewable) before green H2 has a consumer. H2-DRI is the
# sole H2 user and is gated to ng_h2_start_year (No_H2_Before), so building electrolysers
# earlier would make hydrogen nothing can use -- the optimiser only does it to pre-position
# around the Gaussian ramp cap (idle capacity dodging the speed limit). Forbid it: supply
# starts when demand does, so the ramp begins cleanly at the H2 debut.
s.t. h2elec_predebut{t in T: t < ng_h2_start_year}: cap_h2elec[t] = 0;
s.t. h2re_predebut  {t in T: t < ng_h2_start_year}: cap_h2re[t]   = 0;

# Electrolyser capacity must cover green-H2 throughput for H2-DRI ONLY -- the sole H2
# consumer in the model (BF-BOF H2 co-injection removed; n2_h2_hm = 0 -> bf_h2_in = 0).
s.t. h2elec_cover{t in T}:
    h2dri_h2_in[t] <= cap_h2elec[t];
# Dedicated renewable generation (cap_h2re[kW] * 8760 h * CF) must cover the
# electrolyser electricity demand (h2_kwh_per_t per tonne of H2 produced).
s.t. h2re_cover{t in T}:
    h2_kwh_per_t * h2dri_h2_in[t] <= cap_h2re[t] * 8760 * re_cf;

# ----------------------------------------------------------------------------
# Ceiling on ELECTROLYSER capacity additions. ONE constraint, present in every mode;
# only the ceiling VALUE switches (same formalism, different numbers):
#   mode 0: H2_BIGM  -- no limit (counterfactual baseline).
#   mode 1: ramp_frac * H2_cap -- LINEAR additive slab (fixed t-H2/yr each year).
#   mode 2: h2_ref_cap * (rising baseline + Gaussian surge) -- the realistic envelope;
#           does NOT compound off current capacity; amplitude pinned so base(peak)+surge
#           = h2_peak_rate (total peak rate 25%); installed capacity = tilted ramp + S-step.
# All linear -> pure LP. Only electrolysers are bound; renewables follow via h2re_cover.
# The rate is inlined (not a precomputed param) so it re-evaluates on every solve when a
# driver changes h2_ramp_mode / h2_peak_year / ng_h2_start_year on a warm AMPL process.
# Bounds ALLOWED EXPANSION; the optimiser's CHOSEN build (build_h2elec) may sit below.
# Indexed over the full horizon (t > first(T)); no start-year plateau.
s.t. h2elec_growth{t in T: t > first(T)}:
    cap_h2elec[t] - cap_h2elec[prev(t)] <=
        ( if   h2_ramp_mode = 0 then H2_BIGM
          else if h2_ramp_mode = 1 then ramp_frac * H2_cap
          else h2_ref_cap * ( h2_base[t]
                             + (h2_peak_rate
                                - (h2_base_start + (h2_base_end - h2_base_start)
                                                   *(h2_peak_year-2025)/25))
                               * exp( -((t - h2_peak_year)^2)
                                      / (2*h2_gauss_sigma^2) ) ) );

# Close the 2025 edge: h2elec_growth is indexed t>first(T), so without this the first
# year is uncapped and the optimiser pre-builds idle electrolysers in 2025 to dodge the
# ramp. Same value switch as h2elec_growth, anchored at a zero 2024 base, so in modes 1/2
# cap_h2elec[2025] <= allowed_add(2025); mode 0 = H2_BIGM (no limit).
s.t. h2elec_first{t in T: t = first(T)}:
    cap_h2elec[t] <=
        ( if   h2_ramp_mode = 0 then H2_BIGM
          else if h2_ramp_mode = 1 then ramp_frac * H2_cap
          else h2_ref_cap * ( h2_base[t]
                             + (h2_peak_rate
                                - (h2_base_start + (h2_base_end - h2_base_start)
                                                   *(h2_peak_year-2025)/25))
                               * exp( -((t - h2_peak_year)^2)
                                      / (2*h2_gauss_sigma^2) ) ) );
