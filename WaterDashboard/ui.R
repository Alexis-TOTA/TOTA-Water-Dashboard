library(shiny)
library(shinydashboard)
library(jsonlite)
library(bslib)

TOTA_theme <- create_theme(
  adminlte_color(
    light_blue = "#004B55"
  )
)

footer_TOTA <- tags$footer( 
  div(
    div(
      tags$img(
        src = "side_bar_logo.png",
        width = "80%",
        style = "padding-left: 10%;"
      ),
      style = "width: 15%; display: flex; align-items: center; justify-content: center;"
    ),
    
    div(
      p("Thompson Okanagan Tourism Association",
        style = "font-weight: bold; margin-bottom: 5px;"
      ),
      
      p("2280-D Leckie Road, Kelowna,",
        style = "margin-bottom: 2px;"
      ),
      
      p("British Columbia, V1X 6G6",
        style = "margin-bottom: 0;"
      ),
      style = "width: 60%; color: white; display: flex; flex-direction: column; justify-content: center; padding-left: 5%;"
    ),
    
    div(
      tags$p(
        tags$a(
          "Created by Alexis Samp",
          href = "https://ca.linkedin.com/in/alexis-samp-b89678342",
          target = "_blank",
          style ="color: white;"
        ),
        style = "color: white; width: 100%; font-size: 14px; text-align: center; text-decoration: underline;"
      ),
    ),
    style = "width: 100%; background-color: #004B55; display: flex; align-items: center; padding: 20px 5%; box-sizing: border-box; color: white;"
  ),
  style = "position: relative; bottom: 0; left: 0; width: 100%; z-index: 9999;"
)

#USER INTERFACE
ui <- dashboardPage(
  dashboardHeader(title = "TOTA Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Net Inflow", tabName = "net_inflow", icon = icon("square-poll-vertical")),
      menuItem("Water Consumption", tabName = "water_consumption", icon = icon("droplet")),
      menuItem("Okanagan Lake Level", tabName = "mean_daily_level", icon = icon("water")),
      menuItem("Groundwater Wells", tabName = "groundwater_wells", icon = icon("map-location")),
      menuItem("Drought Conditions", tabName = "drought_level", icon = icon("hand-holding-droplet")),
      menuItem("Stream State", tabName = "stream", icon = icon("temperature-three-quarters"))
    ),
    
    tags$img(
      src = "side_bar_logo.png",
      width = "85%",
      style = "position: relative; padding-top: 40px; padding-left: 15%"
    )
  ),
    
  dashboardBody(
    use_theme(TOTA_theme),
    tags$p(style = "font-size: 25px;"),
    tabItems(
      
      tabItem(
        
        tabName = "home",
        
        tags$img(
          src = "banner.png",
          width = "100%",
          style = "position: relative;"
        ),
        
        fluidRow(
            width = "100%",
            
            h2("About this Dashboard"),
            p("The Okanagan watershed supports communities, agriculture, ecosystems, and the tourism experiences that attract visitors to the region.
              This dashboard brings together the Okanagan watershed's water supply, consumption, groundwater, drought levels, lake levels, and 
              stream conditions using publicly available data to support a better understanding of water conditions across the region. 
              The purpose of this dashboard is to support TOTA's water management report for the UN Tourism International 
              Network of Sustainable Tourism Observatories (INSTO) and contributes to ongoing efforts to understand and monitor 
              the relationship between water managment and tourism in the Thompson Okanagan. Understanding how much water is available, 
              how much is being used, and how conditions are changing helps us understand tourism's relationship with the regions water resources."),
            br(),
            p("Explore the indicators below to understand how water conditions are changing and what they mean for the region."),
            br(),
            
            column(
              tags$head(
                tags$style(HTML(".explore-link {
                                    display: block;
                                    font-size: 18px;
                                    font-weight: 600;
                                    margin-top: 10px;
                                    margin-bottom: 10px;
                                    color: #004B55;
                                    text-decoration: none;
                                  }
                                  .explore-link:hover {
                                    text-decoration: underline;
                                    cursor: pointer;
                                  }
                                "))
              ),
              
              width = 6,
              h2("What Can Be Explored?"),
              
              actionLink(
                "net_inflow_link",
                strong("Net Inflow - How much water is available?"),
                class = "explore-link",
                
              ),
              p("View weekly net inflow into Okanagan Lake and compare current conditions with the historical average."),
              
              actionLink(
                "water_consumption_link",
                strong("Water Consumption - How much water are we using?"),
                class = "explore-link"
              ),
              p("Explore annual water consumption by provider and year. Compare providers and examine changes in regional water use."),
              
              actionLink(
                "lake_level_link",
                strong("Okanagan Lake Levels - Is the lake level changing?"),
                class = "explore-link",
              ),
              p("Explore historical and current lake levels and seasonal patterns."),
              
              actionLink(
                "groundwater_link",
                strong("Groundwater Wells - What is happening below ground?"),
                class = "explore-link"
              ),
              p("Explore groundwater monitoring locations across the region, view available well-level information, and compare change over time."),
              
              actionLink(
                "drought_link",
                strong("Drought Conditions - What is happening below ground?"),
                class = "explore-link"
              ),
              p("View current drought conditions across the Thompson Okanagan."),
              
              actionLink(
                "stream_state_link",
                strong("Stream State - - What is happening in streams and ecosystems?"),
                class = "explore-link"
              ),
              p("View current stream water temperatures compared to the sockeye migration barrier."),
              
              br(),
              br(),
              h2("Acknowledgements"),
              p("This project would not have been possible without the support and guidance of the Okanagan Basin Water Board (OBWB) and Nelson Jatel. 
                Thank you for sharing your knowledge and providing valuable feedback throughout the development of this dashboard.")
            ),
            
            tags$style(HTML(".explore-link {
                              color: #42817A;
                              font-size: 18px;
                              font-weight: bold;
                              text-decoration: none;
                            }
                          
                            .explore-link:hover {
                              text-decoration: underline;
                            }
                          ")),
            
            column(
              width = 6,
              tags$img(
                src = "basin_map.jpg",
                width = "85%",
                style = "position: relative; padding-left: 20%"
              ),
              
              tags$p(
                "Source: Okanagan Basin Water Board (OBWB). Okanagan Basin Map. Retrieved from https://obwb.ca/basin_map/",
                style = "font-size: 12px; color: #777; text-align: center; padding-top: 2%;"
              )
              
            ),
            
            style = "position: relative; bottom: 0; width: 100%; padding: 20px;"
        ),
      ),
      
      tabItem(
        tabName = "net_inflow",
        fluidRow(
          
          box(
            title = "Okanagan Lake Net Inflows - Is the lake receiving enough water?",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,     
            plotOutput("netInflowPlot", height = 600),
            footer = "Net inflow tells us how much water is being added to Okanagan Lake (station 08NM083) each week after accounting for water released downstream at Okanagan
                      River at Penticton (station 08NM050). 
                      Comparing current conditions with the historical average helps show whether the lake is receiving more or less water than usual."
            #dynamically generate a sentence based on the selected period:This water year, net inflows are currently below the historical average. or This water year, net inflows are currently above the historical average.
          ),
          
          box(
            title = "References & Data",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12, 
            p("Okanagan Basin Water Board, & Jatel, N. (2026). Okanagan Lake weekly net inflow: 
              current water year versus the 1944–2025 average [Interactive figure]. 
              Retrieved July 20, 2026, from https://okanaganwatersupply.com"),
            p("Data source: Water Survey of Canada, Environment and Climate Change Canada
              (hydrometric stations 08NM083, Okanagan Lake at Kelowna, and 08NM050, Okanagan River at Penticton).")
          )
        ),
      ),
      
      tabItem(
        tabName = "water_consumption" ,
        
        fluidRow(
          box(
            title = "Water Consumption - How much water are we using?",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            p("Put KPIS HERE")
          ),
          
          box(
            title = "Methodology & Data",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            tags$ul(
              tags$li("This dashboard summarizes the best publicly available municipal water consumption data for the Okanagan Watershed."),
              tags$li("Annual water consumption values are based on official utility or municipal reports whenever available."),
              tags$li("Where official annual totals were unavailable, annual values were estimated using publicly available information, including reported monthly water use and publications. Estimates were used only when no official annual total could be identified."),
              tags$li("Missing records indicate that no annual consumption data could be located for that year after reviewing publicly available sources, including annual reports, drinking water reports, council records, and other municipal documents."),
              tags$li("This dashboard currently focuses on the Okanagan watershed, which serves as a pilot study area within the broader Thompson Okanagan region. The Okanagan watershed does not represent the entire Thompson Okanagan region."), 
              tags$li("The Okanagan Watershed was selected because it has the most complete and consistent publicly available data."),
              tags$li("Although there are approximately 300 water utilities in the Okanagan, the largest 10 utilities supply approximately 90% of the region's water. Consequently, the pilot dataset captures the majority of municipal water use despite not including every utility.")
            )
          ),
          
          box(
            title = "Water Consumption Per Year",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            padding = 2,
            plotOutput("ConsumptionPlot", height = 500)
          ),
          
          box(
            title = paste0("Water Source Types Across ", count(df2), " Providers"),
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            plotOutput("WaterSourcePlot")
          ),
          
          box(
            title = "Compare Providers",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            
            fluidRow(
              column(
                width = 3,
                selectInput(
                  "year",
                  "Select Year:",
                  choices = sort(unique(df2_long$Year)),
                  selected = "2024")
              ),
              
              column(
                width = 12,
                selectInput(
                  "provider",
                  "Select Providers:",
                  choices = sort(unique(df2_long$MUN_NAME)),
                  multiple = TRUE,
                  selected = sort(unique(df2_long$MUN_NAME)))
              ),
            ),
            plotOutput("ProvidersPlot", height = 500)
          ),
          
          
          box(
            title = "References",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            p("Samp, A. (2026). Okanagan Water Consumption dataset for the Okanagan Watershed [Data set]. Unpublished dataset.")
          )
        ),
      ),
      
      tabItem(
        tabName = "mean_daily_level",
        fluidRow(
          
            width = 12,
            box(
              title = "Lake Level - Is the lake level changing?",
              width = 12,
              status = "primary",
              solidHeader = TRUE,
              collapsible = TRUE,
              p(paste0("Okanagan Lake levels naturally fluctuate throughout the year because of snowmelt, precipitation, inflows, outflows, and evaporation.
                       Comparing the most recent available year ", max(df_daily_mean$Year), " with historic years provides context for current water conditions. 
                       The daily mean values shown represent the average lake level.")),
              p("Station 08NM083 (Okanagan Lake) is listed as ASSUMED DATUM, this means the station's zero point 
                is an arbitrary reference established for that gauge. A value like 1.4 m means the water surface was 1.4 m above the stations 
                assumed zero.")
            ),
          
          box(
            title = "Historic Vs Recent Mean",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            plotOutput("HistoricalDailyPlot" , height = 600),
            footer = paste0("Okanagan Lake (Station 08NM083); Shaded area shows the historical daily range (",
                            min(df_daily_mean$Year), 
                            "-", 
                            max(df_daily_mean$Year),
                            "); blue line shows ",
                            max(df_daily_mean$Year),
                            " daily mean lake level; pink line shows the historical daily mean.")
          ),
          
          box(
            title = "Mean daily Level of Okanagan Lake Over the last 5 years",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            plotOutput("DailyMeanPast5YearsPlot", height = 600)
          ),
          
          box(
            title = "Mean Level of Okanagan Lake",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            fluidRow(
              column(
                width = 3,
                selectInput(
                  "levelyear",
                  "Select Year:",
                  choices = sort(unique(df_daily_mean$Year)),
                  selected = "2025")
                ) 
              ),
            plotOutput("DailyMeanLevelPlot", height = 500)
          ),
          
          box(
            title = "References & Data",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            p("Data source: Environment and Climate Change Canada. Daily mean of water level or flow dataset. Government of Canada. Hydrometric Station 08NM083. 
              Retrieved via the MSC GeoMet API: https://api.weather.gc.ca/collections/hydrometric-daily-mean/items?f=json&STATION_NUMBER=08NM083&datetime=1990-01-01/.."),
            p("Data source: Environment and Climate Change Canada. Monitoring Stations dataset. Government of Canada. Hydrometric Station 08NM083. Retrieved via the MSC GeoMet
              API: https://api.weather.gc.ca/collections/hydrometric-stations/items?limit=10&offset=0&STATION_NUMBER=08NM083")
          )
        ),
      ),
      
      tabItem(
        tabName = "groundwater_wells",
        fluidRow(
          box(
            title = "Groundwater - What is happening below ground?",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            p("Groundwater is an important part of the region's water system. Observation wells provide a long-term view of groundwater 
              conditions and can help identify changes that may not be immediately visible at the surface.")
            
          ),
          
          box(
            title = "Active and Inactive Groundwater Wells in the Okanagan",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 6,
            leafletOutput("WellPlot", height = 640)
          ),
          
          box(
            title = "Change Over Time",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 6,
            plotOutput("ChangeOverTimePlot", height = 600),
            footer = "Select an active well to view its change over time."
          ),
          
          box(
            title = "References & Data",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            p("Data source: Province of British Columbia. Groundwater Level Data Interactive Map (Provincial Groundwater Observation Well Network).
              Retrieved from https://governmentofbc.maps.arcgis.com/apps/webappviewer/index.html?id=b53cb0bf3f6848e79d66ffd09b74f00d"),
            p("Data source: Province of British Columbia. Groundwater Observation Well Network. Data retrieved through the AQUARIUS WebPortal data export tool.")
          )
        ),
      ),
      
      tabItem(
        tabName = "drought_level",
        fluidRow(
          box(
            title = "Drought - How dry is the region?",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            p("Drought conditions provide important context for understanding water availability across the region. The drought scale combines 
              information about water supply and environmental conditions to indicate the severity of drought.")
          ),
          
          box(
            title = "Current Drought Levels of Basins within the Thompson Okanagan Region",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 6,
            leafletOutput("DroughtPlot", height = 568)
          ),
          
          box(
            title = "Data",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 6,
            htmlOutput("DroughtTable")
          ),
          
          box(
            title = "Drought Scale",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            tags$img(
              src = "drought_scale.png",
              width = "100%"
            ),
            footer = ("Government of British Columbia. B.C. Drought Information Portal. Available at: https://droughtportal.gov.bc.ca/")
          ),
          
          box(
            title = "2025 Drought Levels at a Glance",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            plotOutput("DroughtHistPlot", height = 500)
          ),
          
          box(
            title = "References & Data",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            p("Data source: Province of British Columbia. B.C. Drought Information Portal (British Columbia Drought Levels).
              Retrieved from https://droughtportal.gov.bc.ca/datasets/f1842161d9c2454a98f9fc3b45d5d92e_27/explore?location=54.149730%2C-126.557374%2C5"),
            p("Data source: Government of British Columbia. BC Drought Levels Time Lapse 2025. Drought Information Portal. Retrieved from https://drought-information-portal-bcgov03.hub.arcgis.com/pages/historical-drought-levels")
          )
        ),
      ),
      
      tabItem(
        tabName = "stream",
        fluidRow(
          
          box(
            title = "Stream State - What is happening in streams and ecosystems?",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            p("Stream temperature is an important indicator of aquatic ecosystem health. 19 °C is the water-quality guideline of BC and 21 °C is the sockeye migration barrier. Streams at or above 21 °C
              form a thermal wall that blocks or kills migrating and rearing salmon.")
            #add dymamic text something like:The 7-day average temperature at [station] is currently XX°C, compared with the 21°C migration barrier for sockeye salmon.
          ),
          
          box(
            title = "Okanagan Stream Thermal State",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            plotOutput("StreamStatePlot", height = 500)
          ),
          
          box(
            title = "References & Data",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            p("Jatel, N. and Okanagan Basin Water Board (2026). Okanagan Stream Temperature Dataset. Distributed under CC-BY 4.0. https://temp.stream/.")
          )
        ),
      )
    ),
    footer_TOTA
  )
)

