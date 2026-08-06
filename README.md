# Model Framework


The model uses three learning parameters to represent future technological progress.

- **`theta_tech`** – Represents global technology progress. It affects the cost of green hydrogen by reducing electrolyser and renewable energy costs. It does **not** affect electricity prices or grid emissions in India.

- **`theta_grid`** – Represents the future Indian power system. It affects grid electricity prices, grid emission factor, CCS operating costs, EAF electricity costs, and waste heat recovery benefits.

- **`theta_ccs`** – Represents improvements in carbon capture technology. It controls how much CCS plant capital costs decrease over time. The final cost of carbon capture is calculated from capital cost, electricity, steam, solvent, and transport & storage costs, rather than being set directly.

All three parameters range from **0 to 1**:
- **0** = Slow transition
- **1** = Fast transition

## Capacity Expansion

The model explicitly tracks installed capacity for each steelmaking route. New capacity requires capital investment, has a fixed operating cost, and remains available throughout its lifetime. Annual expansion is limited by technology-specific deployment constraints.

## Capacity Utilization

Production must operate within minimum and maximum utilization limits. The minimum utilization represents the economic requirement for plants to operate above break-even levels, while the maximum utilization accounts for maintenance and operational downtime.

## Green Hydrogen Supply

Instead of using a fixed hydrogen price, the model explicitly represents the green hydrogen supply chain, including:

- Electrolyser capacity
- Dedicated renewable electricity
- Hydrogen firming and storage
- Operating costs

This allows hydrogen investments to become sunk assets that can later be underutilized or stranded.

## Carbon Capture and Storage (CCS)

CCS costs are built from individual components rather than using a single capture cost.

These components include:

- Capture plant capital cost
- Fixed operating cost
- Electricity for compression
- Steam for solvent regeneration
- Solvent consumption
- Transport and storage

This framework allows technology learning and electricity prices to influence the total cost of carbon capture.

## Capacity Expansion Limits

Conventional steelmaking routes share a common annual expansion limit, while hydrogen deployment follows a dedicated ramping model based on electrolyser deployment.

Three hydrogen deployment modes are available:

- **Mode 0:** No deployment limit (counterfactual)
- **Mode 1:** Constant annual expansion rate
- **Mode 2:** Gaussian deployment curve (default)

## Sunk Capital

By default, investments are irreversible. Capital costs are incurred when capacity is built, even if that capacity is later underutilized. A counterfactual mode is also available where capital costs scale with production instead of installed capacity.
