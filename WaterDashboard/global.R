library(shiny)
library(ggplot2)
library(readr)
library(plotly)
library(tidyr)
library(httr)
library(dplyr)
library(lubridate)
library(jsonlite)
library(leaflet)
library(ggtext)
library(shinydashboard)
# library(shinydashboardPlus)
library(bslib)
library(geojsonsf)
library(googlesheets4)
library(sf)
library(fresh)

#OBWB INFLOWS DATA FRAME -------------------------------------------
df <- read_csv("data/OBWB_Inflows.csv")
# Convert dates if needed
df$`Week ending` <- as.Date(df$`Week ending`)

#WATER CONSUMPTION DATA FRAME ------------------------------------------------------------------
df2 <- read_csv("https://docs.google.com/spreadsheets/d/1ar-egzIc56-w4CUB9CEJUuKEXn_58x3rt4EioSd9Fxg/export?format=csv&gid=544661246")

#Converting multiple year columns to one single column
df2_long <- df2 |>
  pivot_longer(
    cols = ends_with("VOL_m³"),
    names_to = "Year",
    values_to = "Consumption"
  )
df2_long$Year <- gsub("_VOL_m³", "", df2_long$Year)

#MONTHLY MEAN of Water Level or Flow 2025 DATA FRAME ----------------------------------------
kelowna_url <- "https://api.weather.gc.ca/collections/hydrometric-monthly-mean/items?f=json&STATION_NUMBER=08NM083&datetime=2000-01-01/.."

kel_call <- GET(kelowna_url)
kel_call$status_code

api_data<- fromJSON(content(kel_call, as = "text"), flatten = TRUE)

df_kelowna <- api_data$features

df_kelowna <- api_data$features |>
  rename_with(~sub("^properties\\.", "", .)) |>
  mutate(
    DATE = ym(DATE),
    Year = year(DATE),
    Month = month(DATE)
  )

#DAILY MEAN OF OKANAGAN LAKE LEVEL DATA FRAME 1990-current--------------------------------------
limit <- 10000
offset <- 0

all_data <- list()

repeat {
  url <- paste0(
    "https://api.weather.gc.ca/collections/hydrometric-daily-mean/items?",
    "f=csv",
    "&STATION_NUMBER=08NM083",
    "&datetime=1990-01-01/..",
    "&properties=IDENTIFIER,DATE,LEVEL",
    "&offset=", offset,
    "&limit=", limit
  )
  message("Downloading offset = ", offset)
  
  df_d <- read_csv(url, show_col_types = FALSE)
  
  # Stop if no rows returned
  if (nrow(df_d) == 0) {
    break
  }
  
  all_data[[length(all_data) + 1]] <- df_d
  
  # If fewer than 'limit' rows, we've reached the end
  if (nrow(df_d) < limit) {
    break
  }
  offset <- offset + limit
}

df_daily_mean <- bind_rows(all_data)

df_daily_mean <- mutate(df_daily_mean,
                        Year = year(DATE),
                        Month = month(DATE),
                        Day = day(DATE),
                        DayOfYear = yday(DATE))

#GROUND WATER MAP DATA FRAME ------------------------------------------------------------------
import_wells <- function(){
  well_ids <- read_csv("data/well locations.csv")$Well
  groups <- split(
    well_ids,
    ceiling(seq_along(well_ids) / 20)
  )
  urls <- lapply(groups, build_url)
  
  all_wells <- lapply(urls, import_one_batch)
  
  do.call(rbind, all_wells)
}

build_url <- function(wells){
  
  base_url <- paste0(
    "https://bcmoe-prod.aquaticinformatics.net/Export/BulkExport?",
    "DateRange=Days7",
    "&TimeZone=0",
    "&Calendar=CALENDARYEAR",
    "&Interval=Daily",
    "&Step=1",
    "&ExportFormat=csv",
    "&TimeAligned=True",
    "&RoundData=True",
    "&IncludeGradeCodes=False",
    "&IncludeApprovalLevels=True",
    "&IncludeQualifiers=True",
    "&IncludeInterpolationTypes=False",
    "&IncludeNotes=undefined"
  )
  
  dataset_string <- paste(
    sapply(seq_along(wells), function(i){
      
      paste0(
        "&Datasets[", i-1, "].DatasetName=SGWL.Working%40", wells[i],
        "&Datasets[", i-1, "].Calculation=Aggregate",
        "&Datasets[", i-1, "].UnitId=306"
      )
    }),
    collapse = ""
  )
  paste0(base_url, dataset_string)
}
import_one_batch <- function(url){
  #Get well IDS
  well_ids <- read.csv(
    url,
    skip = 2,
    nrows = 1,
    header = FALSE,
    stringsAsFactors = FALSE
  )
  
  well_names <- as.character(well_ids[1, 3:ncol(well_ids)])
  #View(well_names)
  
  #Get Data Frame
  df_wells <- read.csv(url, skip = 5)
  names(df_wells) <-
    c("Start", "End", well_names)
  #View(df_wells)
  
  #Pivot Table
  df_wells_long <-
    pivot_longer(
      df_wells,
      cols = -c(Start, End),
      names_to = "Well",
      values_to = "Average_m"
    )
  return (df_wells_long)
}
df_final <- import_wells()

#Read in well locations.csv
well_locations <- read_csv(
  "data/well locations.csv",
  show_col_types = FALSE
)

#Add Lat, Long, & Status to df_final
df_final <- left_join(
  df_final,
  select(well_locations, Well, latitude, longitude, status),
  by = "Well"
)

#only show latest measurement for each well
second_date <- sort(unique(df_final$Start), decreasing = TRUE)[2]

df_map <- df_final %>%
  filter(Start == second_date)

df_map_sf <- st_as_sf(
  df_map,
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
)

#DROUGHT MAP DATA FRAME  ---------------------------------------------------------
#Gets most current drought data
drought_url <- "https://services1.arcgis.com/xeMpV7tU1t4KD3Ei/arcgis/rest/services/British_Columbia_Drought_Levels_(Edit)_view/FeatureServer/27/query?f=geojson&where=(BasinName%20IN%20('Okanagan'%2C%20'South%20Thompson'%2C%20'North%20Thompson'%2C%20'Lower%20Thompson'%2C%20'Kettle%20River'%2C%20'Nicola'%2C%20'Similkameen'))&outFields=*"

geojson <- content(GET(drought_url), "text", encoding = "UTF-8")

df_drought <- geojson_sf(geojson)

#Convert date to our time zone
df_drought$Date_Modified <-
  as.POSIXct(df_drought$Date_Modified / 1000,
             origin = "1970-01-01",
             tz = "America/Vancouver")

#HISTORICAL DROUGHT DATA FRAME ---------------------------------------------------------------------
df_drought_hist <- read_csv("https://docs.google.com/spreadsheets/d/12iOq2W54ObgkNCKXm9qVfQ0C8U_ZGgw8eaUEG-ysYJw/export?format=csv&gid=0")

df_drought_hist <- df_drought_hist |>
  mutate(
    Start_Date = as.Date(
      as.POSIXct(
        Start_Date,
        format = "%m/%d/%Y, %I:%M %p"
      )
    ),
    
    # Convert "Not updated..." to 6
    `Drought Level` = case_when(
      `Drought Level` == "Not updated outside of core drought season" ~ 6,
      TRUE ~ as.numeric(`Drought Level`)
    )
  ) |>
  select(
    `Basin Name`,
    Start_Date,
    `Drought Level`
  ) |>
  arrange(`Basin Name`, Start_Date)

#STREAM THERMAL STATE DATA FRAME --------------------------------------------------
download.file("https://storage.googleapis.com/obwb-okanagan-streamtemp/oktemp_streamtemp_latest.zip",
              destfile = "data/streamtemp/oktemp_latest.zip")
unzip(
  zipfile = "data/streamtemp/oktemp_latest.zip",
  exdir = "data/streamtemp/"
)

df_stream_temp <- read.csv("data/streamtemp/stream_temperature_daily.csv")


