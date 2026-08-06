# Steel-Sector-
Modeling and optimization of steel sector in India: A time series analysis

The model uses three learning parameters to represent future technological progress.

- **`theta_tech`** – Represents global technology progress. It affects the cost of green hydrogen by reducing electrolyser and renewable energy costs. It does **not** affect electricity prices or grid emissions in India.

- **`theta_grid`** – Represents the future Indian power system. It affects grid electricity prices, grid emission factor, CCS operating costs, EAF electricity costs, and waste heat recovery benefits.

- **`theta_ccs`** – Represents improvements in carbon capture technology. It controls how much CCS plant capital costs decrease over time. The final cost of carbon capture is calculated from capital cost, electricity, steam, solvent, and transport & storage costs, rather than being set directly.

Both parameters range from **0 to 1**:
- **0** = Slow transition
- **1** = Fast transition
