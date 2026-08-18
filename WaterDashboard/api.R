library(httr)
library(jsonlite)
library(dplyr)
library(lubridate)
library(readr)
library(tidyr)
library(sf)
df <- read_csv("data/OBWB_Inflows.csv")
# Convert dates if needed
df$`Week ending` <- as.Date(df$`Week ending`)
View(df)
names(df)

#KELOWNA STATION--------------------------------------------------------

#HISTORICAL DATA (1944-2025)  Daily Mean of Water Level or Flow
hist_kelowna_url <- "https://api.weather.gc.ca/collections/hydrometric-daily-mean/items?f=json&STATION_NUMBER=08NM083&datetime=1944-01-01/.."

hist_kel_call <- GET(hist_kelowna_url)

hist_kel_call$status_code


api_data_hk<- fromJSON(content(hist_kel_call, as = "text"), flatten = TRUE)
#class(api_data_hk)
#str(api_data_hk, max.level = 2)

df_hist_Kelowna <- api_data_hk$features

#View(df_hist_Kelowna)

#REAL TIME DATA (2026-07-15 on wards) ------
real_time_kelowna_url <- "https://api.weather.gc.ca/collections/hydrometric-realtime/items?f=json&STATION_NUMBER=08NM083&datetime=2026-06-13/..&limit=10000"

rt_kel_call <- GET(real_time_kelowna_url)

rt_kel_call$status_code


api_data_rtk<- fromJSON(content(rt_kel_call, as = "text"), flatten = TRUE)
#class(api_data_rtk)
#str(api_data_rtk, max.level = 2)

df_rt_Kelowna <- api_data_rtk$features

View(df_rt_Kelowna)
#names(df_rt_Kelowna)

#PENTICTON STATION----------------------------------------------------------

#HISTORICAL DATA (1944-2025)  Daily Mean of Water Level or Flow
hist_penticton_url <- "https://api.weather.gc.ca/collections/hydrometric-daily-mean/items?f=json&STATION_NUMBER=08NM050&datetime=1944-01-01/.."

hist_pen_call <- GET(hist_penticton_url)

hist_pen_call$status_code


api_data_hp <- fromJSON(content(hist_pen_call, as = "text"), flatten = TRUE)
#class(api_data_hp)
#str(api_data_hp, max.level = 2)

df_hist_penticton <- api_data_hp$features

#View(df_hist_penticton)

#REAL TIME DATA (2026-07-15 on wards)----------
real_time_penticton_url <- "https://api.weather.gc.ca/collections/hydrometric-realtime/items?f=json&STATION_NUMBER=08NM050&datetime=2026-06-13/..&limit=10000"
rt_pen_call <- GET(real_time_penticton_url)

rt_pen_call$status_code


api_data_rtp <- fromJSON(content(rt_pen_call, as = "text"), flatten = TRUE)
#class(api_data_rtp)
#str(api_data_rtp, max.level = 2)

df_rt_penticton <- api_data_rtp$features

View(df_rt_penticton)
#names(df_rt_penticton)




#Clean col names	
df_rt_Kelowna <- df_rt_Kelowna |>
  rename_with(~sub("^properties\\.", "", .))

df_rt_penticton <- df_rt_penticton |>
  rename_with(~sub("^properties\\.", "", .))

df_hist_Kelowna <- df_hist_Kelowna |>
  rename_with(~sub("^properties\\.", "", .))

df_hist_penticton <- df_hist_penticton |>
  rename_with(~sub("^properties\\.", "", .))

#Convert timestamps
df_rt_Kelowna <- df_rt_Kelowna |>
  mutate(DATETIME_LST = ymd_hms(DATETIME_LST))

df_rt_penticton <- df_rt_penticton |>
  mutate(DATETIME_LST = ymd_hms(DATETIME_LST))

df_hist_Kelowna <- df_hist_Kelowna |>
  mutate(DATETIME_LST = ymd(DATE))

df_hist_penticton <- df_hist_penticton |>
  mutate(DATETIME_LST = ymd(DATE))



#Aggregate to weekly
# weekly_level <- df_rt_Kelowna |>
#   mutate(
#     WeekEnding = as.Date(DATETIME_LST) +
#       ((3 - wday(DATETIME_LST) + 7) %% 7)
#   ) |>
#   group_by(WeekEnding) |>
#   summarise(
#     Level_m = mean(LEVEL, na.rm = TRUE)
#   )

weekly_level <-
  df_rt_Kelowna |>
  mutate(
    WeekEnding = as.Date(DATETIME_LST) +
      ((3 - wday(DATETIME_LST) + 7) %% 7)
  ) |>
  group_by(WeekEnding) |>
  summarise(
    Level_m = last(LEVEL)
  )

weekly_flow <-
  df_rt_penticton |>
  mutate(
    WeekEnding = as.Date(DATETIME_LST) +
      ((3 - wday(DATETIME_LST) + 7) %% 7)
  ) |>
  group_by(WeekEnding) |>
  summarise(
    Discharge = mean(DISCHARGE, na.rm = TRUE)
  )

#Convert lake level to storage
weekly_level <-
  weekly_level |>
  mutate(
    Level_ft = Level_m * 3.28084,
    Storage = Level_ft * 85000
  )


#Calculate storage change
weekly_level <-
  weekly_level |>
  arrange(WeekEnding) |>
  mutate(
    StorageChange = Storage - lag(Storage)
  )

#Convert discharge to weekly outflow
weekly_flow <-
  weekly_flow |>
  mutate(
    WeeklyOutflow =
      Discharge * 604800 / 1233.48184
  )
#Calculate Real Time Data to Current (ac-ft)
current <-
  left_join(
    weekly_level,
    weekly_flow,
    by = "WeekEnding"
  )
current <-
  current |>
  mutate(
    Current_acft =
      StorageChange +
      WeeklyOutflow
  )
View(current)

head(df_rt_Kelowna$DATETIME_LST)

tail(df_rt_Kelowna$DATETIME_LST)


#Ground Water Wells API Test
# inact_url <- "https://bcmoe-prod.aquaticinformatics.net/Export/BulkExport?DateRange=Days7&TimeZone=-7&Calendar=CALENDARYEAR&Interval=Daily&Step=1&ExportFormat=csv&TimeAligned=True&RoundData=True&IncludeGradeCodes=False&IncludeApprovalLevels=True&IncludeQualifiers=True&IncludeInterpolationTypes=False&IncludeNotes=undefined&Datasets[0].DatasetName=SGWL.Working%40OW384&Datasets[0].Calculation=Aggregate&Datasets[0].UnitId=306&_=1784228270085"
# df_inact_well <- read.csv(inact_url)
# 
# View(df_inact_well)



#trying to scrape real time data for all wells
wells_url <- "https://bcmoe-prod.aquaticinformatics.net/Export/BulkExport?DateRange=Days7&TimeZone=0&Calendar=CALENDARYEAR&Interval=Daily&Step=1&ExportFormat=csv&TimeAligned=True&RoundData=True&IncludeGradeCodes=False&IncludeApprovalLevels=True&IncludeQualifiers=True&IncludeInterpolationTypes=False&IncludeNotes=undefined&Datasets[0].DatasetName=SGWL.Working%40OW384&Datasets[0].Calculation=Aggregate&Datasets[0].UnitId=306&Datasets[1].DatasetName=SGWL.Working%40OW387&Datasets[1].Calculation=Aggregate&Datasets[1].UnitId=306&Datasets[2].DatasetName=SGWL.Working%40OW401&Datasets[2].Calculation=Aggregate&Datasets[2].UnitId=306&Datasets[3].DatasetName=SGWL.Working%40OW402&Datasets[3].Calculation=Aggregate&Datasets[3].UnitId=306&Datasets[4].DatasetName=SGWL.Working%40OW405&Datasets[4].Calculation=Aggregate&Datasets[4].UnitId=306&Datasets[5].DatasetName=SGWL.Working%40OW407&Datasets[5].Calculation=Aggregate&Datasets[5].UnitId=306&_=1784232434079"


library(readr)
library(httr)
library(tidyr)


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

well_locations <- read_csv(
  "data/well locations.csv",
  show_col_types = FALSE
)

df_final <- left_join(
  df_final,
  select(well_locations, Well, latitude, longitude, status),
  by = "Well"
)
#only show latest measurement for each well
second_date <- sort(unique(df_final$Start), decreasing = TRUE)[2]

df_map <- df_final %>%
  filter(Start == second_date)

# View(df_map)
library(httr)
library(jsonlite)
library(geojsonsf)
drought_url <- "https://services1.arcgis.com/xeMpV7tU1t4KD3Ei/arcgis/rest/services/British_Columbia_Drought_Levels_(Edit)_view/FeatureServer/27/query?f=geojson&where=(BasinName%20IN%20('Okanagan'%2C%20'South%20Thompson'%2C%20'North%20Thompson'%2C%20'Lower%20Thompson'%2C%20'Kettle%20River'%2C%20'Nicola'%2C%20'Similkameen'))&outFields=*"

#drought_url <- "https://services1.arcgis.com/xeMpV7tU1t4KD3Ei/arcgis/rest/services/Historical_Drought/FeatureServer/25/query?f=geojson&where=(BasinName%20IN%20('Okanagan'%2C%20'Kettle%20River'%2C%20'South%20Thompson'%2C%20'North%20Thompson'%2C%20'Nicola'%2C%20'Similkameen'%2C%20'Lower%20Thompson'))%20AND%20(DroughtLevel%20IN%20('0'%2C%20'1'%2C%20'2'%2C%20'3'%2C%20'4'%2C%20'5'))&outFields=*"
geojson <- content(GET(drought_url), "text", encoding = "UTF-8")

df_drought <- geojson_sf(geojson)
df_drought$Date_Modified <-
  as.POSIXct(df_drought$Date_Modified / 1000,
             origin = "1970-01-01",
             tz = "America/Vancouver")

View(df_drought)


#Daily mean lake level
# library(httr)
# library(jsonlite)
# library(readr)
# daily_kelowna_url <- "https://api.weather.gc.ca/collections/hydrometric-daily-mean/items?f=json&STATION_NUMBER=08NM083&datetime=1990-01-01/.."
# 
# 
# daily_api_call<- GET(daily_kelowna_url)
# data_api<- fromJSON(content(daily_api_call, as = "text"), flatten = TRUE)
# df_daily_mean <- data_api$features
# View(df_daily_mean)



library(readr)
library(dplyr)
library(lubridate)

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
  
  df <- read_csv(url, show_col_types = FALSE)
  
  # Stop if no rows returned
  if (nrow(df) == 0) {
    break
  }
  
  all_data[[length(all_data) + 1]] <- df
  
  # If fewer than 'limit' rows, we've reached the end
  if (nrow(df) < limit) {
    break
  }
  
  offset <- offset + limit
}

df_daily_mean <- bind_rows(all_data)

df_daily_mean <- mutate(df_daily_mean,
                        Year = year(DATE),
                        Month = month(DATE),
                        Day = day(DATE))
View(df_daily_mean)


library(googlesheets4)
library(readr)
df_sheets <- read_csv("https://docs.google.com/spreadsheets/d/1ar-egzIc56-w4CUB9CEJUuKEXn_58x3rt4EioSd9Fxg/export?format=csv&gid=544661246")
# View(df_sheets)


library(readr)
download.file("https://storage.googleapis.com/obwb-okanagan-streamtemp/oktemp_streamtemp_latest.zip",
              destfile = "data/streamtemp/oktemp_latest.zip")
unzip(
  zipfile = "data/streamtemp/oktemp_latest.zip",
  exdir = "data/streamtemp/"
  )

df_stream_temp <- read.csv("data/streamtemp/stream_temperature_daily.csv")
# length(unique(df_stream_temp$station))
# df_metadata <- read.csv("data/streamtemp/station_metadata.csv")
# View(df_metadata)
View(df_stream_temp)



#AMOUNT OF FISH -- NEED TO GET SESSION ID SOME HOW TO MAKE THIS WORK
library(readr)
df_fish = read_csv("data/okanagan_fish.csv")


df_fish_filtered <- filter(df_fish, site_name == "Wells Dam")
df_fish_filtered <- select(df_fish_filtered, site_name, species, date, year, value, unit)
df_fish_filtered <- filter(df_fish_filtered, unit == "fish" )

View(df_fish_filtered)

library(readr)
df_drought_hist <- read_csv("https://docs.google.com/spreadsheets/d/12iOq2W54ObgkNCKXm9qVfQ0C8U_ZGgw8eaUEG-ysYJw/export?format=csv&gid=0")
View(df_drought_hist)

