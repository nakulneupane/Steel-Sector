# Steel-Sector-
Modeling and optimization of steel sector in India: A time series analysis
The model uses two learning parameters to represent future technological progress.

- **`theta_tech`** – Represents global technology progress. It affects the cost of green hydrogen by reducing electrolyser and renewable energy costs. It does **not** affect electricity prices or grid emissions in India.

- **`theta_grid`** – Represents the future Indian power system. It affects grid electricity prices, grid emission factor, CCS operating costs, EAF electricity costs, and waste heat recovery benefits.

Both parameters range from **0 to 1**:
- **0** = Slow transition
- **1** = Fast transition
