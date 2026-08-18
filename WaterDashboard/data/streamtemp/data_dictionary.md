# Data dictionary — `stream_temperature_daily.csv`

The primary file in the **Okanagan Stream Temperature Dataset** distribution.
One row per station × per date. Daily mean values aggregated from
WSC's near-real-time feed, then accumulated past WSC's rolling
577-day window so the record grows indefinitely.

## Columns

### `station`
- **Type:** text
- **Definition:** Water Survey of Canada (WSC) station identifier.
- **Format:** seven-character upper-case code (e.g. `08NM053`, `08LG010`).
  Letters 1–4 indicate the sub-sub-drainage (`08NM` = Okanagan main valley,
  `08NL` = Shuswap–Adams, `08LG` = upper Fraser tributaries — confirm per
  station in `station_metadata.csv`); letters 5–7 are the station serial.
- **Source:** WSC station registry, exposed via
  `tidyhydat::realtime_ws()`.
- **Example:** `08NM053`.

### `date`
- **Type:** ISO-8601 date (`YYYY-MM-DD`)
- **Definition:** UTC calendar date the daily-mean values apply to.
- **Note on timezone:** WSC's near-real-time records are timestamped in UTC.
  Aggregating to a UTC date keeps the dataset directly joinable to any
  other UTC-stamped daily product (ECCC ECMD, MODIS, ERA5). To work in
  Pacific Time, shift values by one row (typically negligible at daily
  resolution for thermal regime analysis).
- **Missing-value convention:** never missing for a row that exists.
- **Example:** `2026-05-20`.

### `water_temp`
- **Type:** numeric (`Float64`)
- **Units:** degrees Celsius (°C).
- **Definition:** Daily mean stream temperature for the station on the
  given date, computed from sub-daily measurements within
  the UTC calendar day.
- **Source:** WSC parameter code `TW` (water temperature), aggregated by
  `daily_stats_per_station()` in this project.
- **Quality control:** sub-daily observations passed through
  `realtime_qaqc` (this project's QC layer) before aggregation;
  see `provenance.csv` and the README for the QC summary. Records flagged
  as instrument-fault or sentinel values are dropped before the daily
  mean is taken; the mean is computed over surviving sub-daily values
  for that UTC day.
- **Missing-value convention:** empty string (CSV) / NA (R) / null (parquet).
  A missing value means insufficient surviving sub-daily observations
  for that station × date.
- **Example:** `13.4`.

### `discharge`
- **Type:** numeric (`Float64`)
- **Units:** cubic metres per second (m³·s⁻¹).
- **Definition:** Daily mean stream discharge for the station on the
  given date, included because WSC reports the `QR` parameter at most
  of the same stations as `TW`. Not the primary product of this
  dataset, but provided as concurrent supporting context for any
  user joining stream temperature to flow regime
  (recession analysis, thermal–flow coupling, exposure normalisation).
- **Source:** WSC parameter code `QR` (real-time discharge), aggregated
  the same way as `water_temp`.
- **Quality control:** same `realtime_qaqc` pass; daily mean of
  surviving sub-daily values.
- **Missing-value convention:** empty string / NA / null. A station may
  report `TW` but not `QR` on a given date (and vice versa); the row
  is kept if EITHER variable is present, so `discharge` may be missing
  while `water_temp` is not.
- **Example:** `8.7`.

## Companion files

### `station_metadata.csv`
- One row per `station`. Coordinates, name, drainage area, period of
  record, source provenance. Columns: `station`, `name`, `lat_dd`,
  `lon_dd`, `drainage_area_km2`, `first_banked_date`, `last_banked_date`,
  `n_obs`. Coordinates in decimal degrees, NAD83 datum (as published by
  WSC).

### `provenance.csv`
- Append-only log of pipeline refresh events that contributed to the
  bank. One row per pipeline run. Columns: `refresh_timestamp_utc`,
  `pipeline_run_id`, `n_stations`, `n_rows`, `source_window_start`,
  `source_window_end`, `software_version`. Lets a downstream user
  reconstruct exactly when each segment of the record was banked.

### `README.md`
- One-page plain-language overview, license, citation, contact, and
  links to upstream sources. Generated freshly on each export with
  the current snapshot date and row counts in the header.

## Conventions

- **Encoding:** UTF-8.
- **Line endings:** Unix (`\n`).
- **Delimiter:** comma (`,`); no quoting unless required by RFC 4180.
- **Header row:** present; column names match this dictionary exactly.
- **Sort order:** `station` ascending, then `date` ascending.
- **Decimal separator:** period (`.`).
- **Numeric precision:** floats serialised at full R `digits=7`
  precision (the WSC source resolution is ~0.1 °C for TW and ~0.01
  m³·s⁻¹ for QR; the extra digits carry no real signal but are
  preserved verbatim from the source).

## Versioning

- Each daily export is written as `oktemp_streamtemp_YYYY-MM-DD.zip`
  to the public bucket and indexed by date.
- A `oktemp_streamtemp_latest.zip` alias is kept pointing at the most
  recent successful export.
- Long-term archival to Zenodo with citable DOIs is planned (Phase 2);
  until that lands, cite by date-stamped ZIP filename.

## License and citation

See `README.md`. Distributed under **CC-BY 4.0**.

Citation:

> Jatel, N. and Okanagan Basin Water Board (2026). *Okanagan Stream
> Temperature Dataset* (snapshot YYYY-MM-DD). Distributed under
> CC-BY 4.0. Available at https://temp.stream/.
