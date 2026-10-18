# Results and Discussion — Climate exposure around Aadi Pattam in the Cauvery Delta, 2023–2026

## Study objective

Describe how precipitation timing, temperature, relative humidity, approximate vapour-pressure deficit (VPD) and reference evapotranspiration (ET₀) varied **before and during the July–August Aadi Pattam establishment period** across four recent years. The aim is to identify conditions relevant to future on-farm assessment, **not** to infer measured crop losses from weather alone.

## Data and methods

The analysis uses Open-Meteo ERA5-based gridded daily weather data for eight selected locations in and adjoining the Cauvery Delta agricultural belt (including Karaikal, Puducherry), from 1 April 2023 to 10 October 2026. The R script checks date completeness, duplicates, negative precipitation and missing required variables. There are **10,312 location-day records**, without missing location-date records in the covered interval.

Two location pairs have identical precipitation time series: **Karaikal–Mayiladuthurai** and **Nagapattinam–Tiruvarur**. Precipitation summaries therefore average the six unique time series once each. Temperature, RH, ET₀ and VPD proxy are averaged over eight sample points. Results are neither an area-weighted official Cauvery Delta Zone aggregate nor direct meteorological station observations.

ET₀ is the FAO-56 reference evapotranspiration variable **provided by the data service**, not newly calculated here from raw radiation and wind measurements. A simplified approximate VPD proxy is calculated as `0.6108 × exp(17.27 T/(T+237.3)) × (1 − RH/100)` from daily mean T (°C) and RH (%). It is not leaf-to-air VPD. The optional daily-maximum VPD comes from the service and is plotted separately.

Pre-Aadi is defined operationally as **April–June (91 days)** and Aadi as **July–August (62 days)**. These are practical analysis windows, not universal crop calendars. Comparisons after September 2026 end on 10 October; October 2026 is a partial month and **must not** be compared with complete past Octobers without date matching.

## Results

### 1. Pre-Aadi: April–June

| Year | Rainfall (mm) | ET₀ (mm) | Mean T (°C) | Mean RH (%) | VPD proxy (kPa) | Days with rainfall under 1 mm |
|---|---:|---:|---:|---:|---:|---:|
| 2023 | 215.6 | 507.7 | 30.01 | 71.59 | 1.23 | 63 |
| 2024 | 333.6 | 475.9 | 30.03 | 74.58 | 1.10 | 53 |
| 2025 | 171.5 | 518.9 | 30.17 | 68.86 | 1.35 | 64 |
| **2026** | **158.3** | **532.2** | **30.24** | **70.18** | **1.30** | **65** |

The 2026 pre-Aadi period had the lowest sampled rainfall and highest ET₀ of the four years. It was not uniformly the driest atmospheric environment: for example, its average RH was greater and mean VPD proxy lower than in 2025. The April–June rainfall contrast does **not** establish the soil-water conditions experienced at sowing, because soil storage, runoff, canal flows and irrigation are not measured.

### 2. Aadi Pattam: July–August

| Year | Rainfall (mm) | ET₀ (mm) | Mean T (°C) | Mean RH (%) | VPD proxy (kPa) | Dry days (rain under 1 mm) | Days with eight-point mean Tmax above 35°C |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2023 | 120.7 | 356.4 | 30.22 | 65.49 | 1.51 | 37 | 23 |
| 2024 | 177.5 | 327.1 | 29.54 | 69.06 | 1.30 | 26 | 5 |
| 2025 | 91.3 | 354.8 | 29.94 | 62.91 | 1.60 | 43 | 24 |
| **2026** | **52.9** | **379.6** | **30.52** | **63.12** | **1.63** | **45** | **42** |

In July–August 2026, rainfall was **42.0% lower** than in the same two months of 2025, whereas ET₀ was **7.0% higher**. The mean air temperature was **0.58°C higher**. The eight-location average of daily maximum temperature exceeded 35°C on **42 days** in 2026 compared with **24 days** in 2025. These are descriptive exposure indicators—not evidence of a measured increase in crop failure or yield loss.

Rainfall accumulated more slowly through July–August 2026 than in the other three years, with a particularly low July estimate (**13.6 mm across the six unique precipitation series**). The 2026 mean RH was almost identical to 2025; we therefore do **not** claim that lower humidity caused the 2026 conditions.

### 3. Same-date July 1–October 10 comparison

| Year | Rainfall (mm) | ET₀ (mm) | Mean T (°C) | Mean RH (%) | VPD proxy (kPa) |
|---|---:|---:|---:|---:|---:|
| 2023 | 242.2 | 557.0 | 29.74 | 68.92 | 1.32 |
| 2024 | 250.9 | 548.5 | 29.75 | 68.08 | 1.36 |
| 2025 | 191.7 | 563.9 | 29.72 | 65.24 | 1.48 |
| **2026** | **109.3** | **604.5** | **30.35** | **65.13** | **1.52** |

Over this matched 102-day window, 2026 precipitation was approximately **43% below** 2025, whereas reference ET₀ was **7.2% higher**. These are conditions at the sampled gridded points, not observed field-scale soil-water deficits.

## Discussion and implications for sustainable crop management

The **timing of precipitation**, particularly during the July–August establishment period, is more informative for crop management than a single full-season total. The 2026 analysis shows low early-season rainfall and relatively high atmospheric demand. Even with irrigation, seedlings may encounter damaging heat exposure under some field or garden conditions; however, this dataset lacks leaf temperature, soil moisture, crop type, seedling injury observations, planting dates and measured irrigation supply, so **the mechanism and magnitude of any actual plant injury cannot be identified from this analysis alone**.

The April–June conditions could influence moisture available entering the establishment period, but the present four-year descriptive comparison does **not** test a lagged soil-water or yield response. The results support field testing—not a quantitative claim—of integrated strategies such as local rain gauges, soil-water sensors, crop-stage monitoring, adaptive irrigation scheduling and temporary protection against excessive seedling heat exposure. These should be evaluated for water-use efficiency and crop establishment in properly monitored trials.

## Limitations and conclusion

The four-year window demonstrates recent climate **variability**, not a statistically established long-term climate-change trend or causal El Niño effect. ERA5-based grids cannot confirm rainfall at an individual farm, particularly where brief convective events vary over short distances. The six rainfall grid series are not independent field stations and cannot represent official district or zone averages. Reference ET₀ is atmospheric reference demand, not observed actual evapotranspiration, soil moisture deficit, or irrigation requirement.

**Conclusion:** Across the sampled Delta-area grids, April–June 2026 was relatively rain-poor, and July–August 2026 combined the lowest rainfall with the highest ET₀ and highest number of hot days of the four recent establishment windows. The findings justify further investigation of climate-informed seedling-establishment and resource-management strategies, but do not demonstrate their realized benefits.

## Source references

- Open-Meteo Historical Weather API: https://open-meteo.com/en/docs/historical-weather-api
- Copernicus Climate Data Store: https://cds.climate.copernicus.eu/
- FAO-56: https://www.fao.org/4/x0490e/x0490e00.htm
- Detailed machine-readable results: [outputs/](outputs/)
