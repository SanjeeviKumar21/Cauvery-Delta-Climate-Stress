# Data provenance and reproducibility

## Origin and completeness

The project originates from the user's Open-Meteo ERA5-based multi-site weather export, analyzed in RStudio. The uploaded `outputs.zip` contains the user-executed R's per-site daily table, model-derived plots and summaries. The reviewed tables cover **2023-04-01 to 2026-10-10**, **8 location IDs**, **10,312 rows**, and no missing location-date records.

**Important:** The original expanded April–October Open-Meteo CSV from the user's Mac was **not** included with the uploaded `outputs.zip`. To make this repository self-contained, the present `data/full_apr2023_oct2026.csv` has been **reconstructed from the user's R-generated `outputs/daily_by_site.csv`**, reusing the site-coordinate metadata from the earlier successfully uploaded Open-Meteo export. No weather values were invented or interpolated. The per-site values in this reconstructed file match the processed R records, including temperature, RH, rainfall, ET₀, daily maximum temperature and maximum VPD.

That reconstructed file is **analysis-compatible reproducibility input, not the untouched original API response**. Researchers who need the raw-original data lineage should re-download the identical variables/dates/locations from the documented provider or retrieve the source CSV from the original project owner. Do not describe this copy as independent observational validation.

## Geographic scope

- Eight sampling points named Thanjavur, Kumbakonam, Tiruvarur, Mannargudi, Mayiladuthurai, Sirkazhi, Nagapattinam, and Karaikal.
- Karaikal is in Puducherry. This is a **sampled-area analysis**, not a polygon-masked or area-weighted Tamil Nadu Cauvery Delta Zone mean.
- Identical precipitation series: Karaikal/Mayiladuthurai and Nagapattinam/Tiruvarur. Aggregate precipitation uses the six unique time series once each. This deduplication does not make them six independent rain gauges.

## Method audit

- All 10,312 site-day records have complete date, temperature, RH, precipitation and ET₀ values.
- No observed station rain-gauge or ground-truth yield/irrigation data were available.
- `outputs/QC_MISSING_SITE_DATES.csv` contains no missing site dates.
- The R-generated summaries and PNG plots were inspected. Numeric summaries were independently cross-checked against `daily_by_site.csv` using a second implementation.
- R source code included is the original user-run analysis script. It should reproduce summaries and plots using the reconstructed input, although this bundled copy has **not been rerun in an R installation in this environment**.

## Credits

Weather data by Open-Meteo.com; contains modified Copernicus Climate Change Service information. See https://open-meteo.com/en/docs/historical-weather-api and https://cds.climate.copernicus.eu/. For high-stakes research or operational agriculture, verify against local observations before drawing field conclusions.
