# Okanagan Stream Temperature Dataset

**Snapshot:** 2026-08-18  
**Distribution version:** 16a30895c19f  
**License:** CC-BY 4.0 — see `LICENSE.md`.

## Citation

> Jatel, N. and Okanagan Basin Water Board (2026). *Okanagan Stream
> Temperature Dataset* (snapshot 2026-08-18). Distributed under CC-BY 4.0. Available at https://temp.stream/.

A long-term archival DOI (Zenodo) will be assigned in a future release;
where available, cite that DOI in addition to or in place of the URL.

## What this is

A daily, station-level record of stream temperature for ~26 Water Survey of Canada (WSC) gauging stations in the Okanagan Basin,
British Columbia. Distributed because the upstream WSC near-real-time
feed serves a fixed rolling 577-day window; the Okanagan Basin Water
Board (OBWB) banks observations past that window so the record grows
indefinitely and can support multi-year analyses (climate-warming
trends, sockeye thermal-corridor evaluation, EFN risk forecasting).

**Coverage:**

- Stations: 26 WSC stream-temperature gauges in the
  Okanagan Basin (sub-drainages 08LG, 08NL, 08NM). See
  `station_metadata.csv` for the full list with coordinates,
  drainage areas, and per-station period of record.
- Records: 17,386 station × date rows
  spanning 2024-10-19 to 2026-08-18.
- Update cadence: daily snapshot (this file is regenerated each day
  with the latest available bank). The bank itself updates every 3 h
  internally; the date-stamped public file stabilises at the last
  write of the day.

## Files in this distribution

- `stream_temperature_daily.csv` — the primary data, one row per
  station × date.
- `station_metadata.csv` — one row per station (name, coordinates,
  drainage area where known, period of record).
- `provenance.csv` — pipeline refresh log: every bank update that
  contributed to this snapshot.
- `data_dictionary.md` — column-by-column definitions, units, QC,
  missing-value convention.
- `LICENSE.md` — full CC-BY 4.0 terms, attribution guidance, and the
  upstream-WSC source acknowledgement.

## Source and curation

- **Upstream source:** Water Survey of Canada, Environment and Climate
  Change Canada, near-real-time feed. WSC source data is under the
  Open Government Licence — Canada (OGL-Canada 2.0).
- **Curated by:** Okanagan Basin Water Board (OBWB) Water Stewardship
  Programme. The OBWB contribution is the long-term banking, project
  QAQC, daily aggregation, and station-metadata harmonisation.
- **Compose attribution:** CC-BY 4.0 and OGL-Canada 2.0 attribution
  requirements compose — please credit BOTH OBWB (this curated
  product) and WSC/ECCC (the upstream observations) in any derived
  work.

## How to read it

The primary file is a plain CSV (UTF-8, comma-delimited, header row,
Unix line endings). It opens in Excel, Google Sheets, Python pandas,
R, SQL, or any text editor.

Quick Python (pandas) example:

```python
import pandas as pd
df = pd.read_csv('stream_temperature_daily.csv', parse_dates=['date'])
df.groupby('station')['water_temp'].agg(['mean', 'max']).sort_values('max')
```

Quick R example:

```r
df <- read.csv('stream_temperature_daily.csv')
df$date <- as.Date(df$date)
aggregate(water_temp ~ station, data = df,
          FUN = function(x) c(mean = mean(x, na.rm = TRUE),
                              max  = max(x,  na.rm = TRUE)))
```

## Contact and contributions

- **Maintainer:** Nelson Jatel (`njatel@limnology.ca`),
  Water Stewardship Director, Okanagan Basin Water Board.
- **Issues / questions about the data:** see contact above.
- **Source code that builds this dataset:**
  https://github.com/Okanagan-Basin-Water-Board/oktemp

## Versioning

- Each day's snapshot is published as `oktemp_streamtemp_YYYY-MM-DD.zip`
  in the public bucket and is the citable handle until the Zenodo
  DOI is in place.
- A stable alias `oktemp_streamtemp_latest.zip` always points at the
  most recent successful export.

