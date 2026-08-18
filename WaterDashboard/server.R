# Server
server <- function(input, output, session) {
  
  # NET INFLOWS BAR CHART
  output$netInflowPlot <- renderPlot({
    
    df_long <- df |>
      tidyr::pivot_longer(
        cols = c(`1944-2025 avg (ac-ft)`, `Current (ac-ft)`),
        names_to = "Series",
        values_to = "Inflow"
      ) |>
      mutate(
        Series = recode(
          Series,
          `1944-2025 avg (ac-ft)` = "1944–2025 Average",
          `Current (ac-ft)` = "Current Water Year"
        )
      )
    
    ggplot(
      df_long,
      aes(
        x = `Week ending`,
        y = Inflow,
        fill = Series
      )
    ) +
      
      geom_col(
        position = position_dodge(width = 5),
        width = 7
      ) +
      
      scale_fill_manual(
        values = c(
          "1944–2025 Average" = "#BCB49E",
          "Current Water Year" = "#76ACA9"
        ),
        name = "Series"
      ) +
      
      scale_x_date(
        date_breaks = "1 month",
        date_labels = "%b\n%Y",
        expand = c(0, 0)
      ) +
      
      scale_y_continuous(
        breaks = seq(-10000, 50000, by = 5000)
      ) +
      
      labs(
        title = paste0(
          "Weekly Net Inflow to Okanagan Lake: Current Water Year ",
          format(min(df$`Week ending`), "%Y"),
          "/",
          format(max(df$`Week ending`), "%Y")
        ),
        x = "",
        y = "Net Weekly Inflow Volume (acre-feet)"
      ) +
      
      theme(
        plot.title = element_text(size = 22),
        axis.title = element_text(size = 22),
        axis.text = element_text(size = 16),
        legend.title = element_text(size = 20),
        legend.text = element_text(size = 16)
      )
  })
  
  #COMPARE OKANAGAN PROVIDERS ANNUAL CONSUMPTION BAR CHART
  output$ProvidersPlot <- renderPlot({
    
    filtered_df2 <- df2_long |>
      dplyr::filter(MUN_NAME %in% input$provider,
                    Year == input$year)
    
    ggplot(filtered_df2, aes(x = MUN_NAME, y = Consumption)) +
      geom_col(fill = "#76ACA9", width = 0.25) +
      
      scale_y_continuous(
        breaks = seq(0, 100000000, by = 2000000),
        labels = function(x) paste0(x / 1e6, "M"),
        expand = c(0, 0))+
      
      
      theme(
        axis.text.x = element_text(
          angle = 30,
          hjust = 1,
          size = 14,
          vjust = 1
        ))+
      
      labs(
        x = "Provider",
        y = "Consumption (m³)") +
      theme(plot.title = element_text(face = 'bold'), axis.title = element_text(size = 22), axis.text = element_text(size = 12))
  })
  
  #COMPARE WATER SOURCE DOUGGHNUT CHART
  output$WaterSourcePlot <- renderPlot({
    
    df2_count <- df2_long |>
      distinct(MUN_NAME, WATER_SOURCE) |>
      count(WATER_SOURCE)
    
    # Create legend labels
    labels <- paste0(df2_count$WATER_SOURCE, " (", df2_count$n, ")")

    ggplot(df2_count, aes(x = 2, y = n, fill = WATER_SOURCE)) +
      geom_col(width = 1, color = "white") +
      coord_polar(theta = "y") +
      xlim(0.5, 2.5) +
      scale_fill_manual(
        values = c(
          "Surface Water" = "#76ACA9",
          "Groundwater" = "#D11B4A",
          "Mixed" = "#F6BC1A"
        ),
        labels = labels) +
      theme_void() +

      theme(plot.title = element_text(face = 'bold'), legend.title = element_blank(), 
            legend.text =  element_text(size = 18))
  })
  
  #ANNUAL WATER CONSUMPTION BAR CHART
  output$ConsumptionPlot <- renderPlot({
    
    df2_long <- df2_long |>
      mutate(Year = as.numeric(Year)) |>  #change Year string to number
      group_by(Year) |>
      summarise(
        Consumption = sum(Consumption, na.rm = TRUE) #Sum consumption for each year
      )
    
    ggplot(df2_long, aes(x = Year, y = Consumption))+
      geom_col(fill = "#76ACA9", linewidth = 1.5) +
      coord_flip() +
      
      scale_y_continuous(
        breaks = seq(0, 1000000000, by = 10000000),
        labels = function(x) paste0(x / 1e6, "M"),
        expand = expansion(mult = c(0, 0.05))
        )+
      
      labs(
        x = "Year",
        y = "Consumption (m³)") +
      theme(plot.title = element_text(face = 'bold'), axis.title = element_text(size = 22), axis.text = element_text(size = 16))
  })
  
  #Store selected well
  selectedWell <- reactiveValues(Well = NULL, status = NULL)

  #MAP OF ACTIVE AND INACTIVE WELLS 
  output$WellPlot <- renderLeaflet({

    m_base <- leaflet(data = df_map)
    m_tiles <- addTiles(m_base)

    m_markers <- addCircleMarkers(m_tiles,
                                  lng = ~longitude,
                                  lat = ~latitude,
                                  layerId = ~Well,
                                  radius = 8,
                                  color = ~ifelse(status == "Active", "forestgreen", "red"),
                                  stroke = TRUE,
                                  fillOpacity = 0.8,
                                  label = paste0(df_map$Well, " - ", df_map$status),
                                  popup = ~ifelse(status == "Active", paste0( "<b>Well:</b> ", Well,
                                                                              "<br><b>Status:</b> ", status,
                                                                              "<br><b>Updated:</b> ", as.Date(Start, format = "%Y-%m-%d"),
                                                                              "<br><b>Average Level:</b> ", ifelse(is.na(Average_m), "NA", paste0(Average_m, " m"))),
                                                                      paste0( "<b>Well:</b> ", Well,
                                                                              "<br><b>Status:</b> ", status)
                                                  )
    )

    setView(m_markers, lng = -119.496, lat = 49.880, zoom = 8)
  })

  observeEvent(input$WellPlot_marker_click, {

    selectedWell$Well <- input$WellPlot_marker_click$id

    selectedWell$status <- df_map$status[df_map$Well == selectedWell$Well]
  })

  well_data <- reactive({
    req(selectedWell$Well)

    url_string <- build_url(selectedWell$Well)
    url_string <- sub("Days7", "Years1", url_string)
    print(url_string)
    read.csv(url_string, skip = 5)
  })
  
  #CHANGE IN GROUND WATER LEVEL OVER 1 YEAR LINE CHART
  output$ChangeOverTimePlot <- renderPlot({
    df_w <- well_data()
    
    names(df_w) <-
    c("Start", "End", "Average_m")
    
    df_w$Start <- as.Date(df_w$Start)
    
    status_color <- if (selectedWell$status == "Active") "forestgreen" else "red"

    ggplot(df_w, aes(x = Start, y = Average_m)) +
      
      geom_line(color = "#42817A", linewidth = 1.5) +
      
      geom_smooth(
        method = "lm",
        se = FALSE,
        color = "#D11B4A",
        linewidth = 1
      ) + 
      
      labs(
        title = paste0("Groundwater Level - ",
                            selectedWell$Well,
                            " <span style='color:",
                            status_color,
                            ";'>(",
                            selectedWell$status,
                            ")</span>"),
        
        subtitle = if (selectedWell$status == "Active") "" else "The groundwater level change over time is only available for active wells",
        x = "Month", 
        y = "Average Water Level Below Ground Surface (m)"
      )+ 
      
      theme(
        plot.title = ggtext::element_markdown(hjust = 0.5, face = "bold", size = 16), 
        plot.subtitle = ggtext::element_markdown(hjust = 0.5, size = 14),
        axis.title = element_text(size = 22), 
        axis.text = element_text(size = 16),
          axis.text.x = element_text(
            angle = 30,
            hjust = 0.5,
            size = 14,
            vjust = 0.5
          )
      )+
      
      scale_x_date(
        date_breaks = "1 month",
        date_labels = "%b-%y",
        expand = c(0,0)) +
    
      scale_y_reverse()
  })
  
  #DROUGHT MAP OF THOMPSON OKANAGAN REGION
  output$DroughtPlot <- renderLeaflet({

    pal <- colorFactor(
      palette = c(
        "#FFFFFF",  # 0
        "#EBD1B8",  # 1
        "#B5966B",  # 2
        "#8B6739",  # 3
        "#654727",  # 4
        "#3D2A17"   # 5
      ),
      domain = c(0, 1, 2, 3, 4, 5),
    )

    m_base <- leaflet(data = df_drought)

    m_tiles <- addTiles(m_base)

    m_ploy <-  addPolygons(
      m_tiles,
      fillColor = ~pal(DroughtLevel),
      fillOpacity = 0.75,
      weight = 1.5,
      color = "black",
      popup = ~paste0(
        "<b>", BasinName, "</b><br>",
        "Current Drought Level: ", DroughtLevel
      )
    )

     m_legend <- addLegend(
        m_ploy,
        "bottomright",
        pal = pal,
        values = c(0, 1, 2, 3, 4, 5),
        title = "Drought Level"
      )
    setView(m_legend, lng = -120.34, lat = 50.98, zoom = 6)
  })
  
  #DROUGHT TABLE
  output$DroughtTable <- renderUI({
    
    tags$table(
      class = "table table-striped table-sm",
      tags$thead(
        tags$tr(
          tags$th("Basin"),
          tags$th("Drought Level"),
          tags$th("Latest Update")
        )
      ),
      
      tags$tbody(
        lapply(seq_len(nrow(df_drought)), function(i) {
          
          tags$tr(
            tags$td(df_drought$BasinName[i]),
            tags$td(df_drought$DroughtLevel[i]),
            tags$td(format(df_drought$Date_Modified[i], "%Y-%m-%d %H:%M %p"))
          )
        })
      )
    )
  })
  
  #DROUGHT HISTORY HEATMAP TABLE
  output$DroughtHistPlot <- renderPlot({
    
    df <- df_drought_hist |>
      mutate(
        Date_Label = format(Start_Date, "%d-%b")
      )
    
    df$`Basin Name` <- factor(
      df$`Basin Name`,
      levels = rev(unique(df$`Basin Name`))
    )
    
    # Keep dates in chronological order
    df$Date_Label <- factor(
      df$Date_Label,
      levels = unique(df$Date_Label)
    )
    
    ggplot(
      df,
      aes(
        x = Date_Label,
        y = `Basin Name`,
        fill = factor(`Drought Level`)
      ),
    ) +
      
      # Heatmap cells
      geom_tile(
        color = "black",
        linewidth = 0.25
      ) +
      
      # Numbers / * inside cells
      geom_text(
        aes(
          label = ifelse(
            `Drought Level` == 6,
            "*",
            `Drought Level`
          )
        ),
        size = 3
      ) +
      
      # Drought colours
      scale_fill_manual(
        values = c(
          "0" = "#FFFFFF",
          "1" = "#EBD1B8",
          "2" = "#B5966B",
          "3" = "#8B6739",
          "4" = "#654727",
          "5" = "#3D2A17",
          "6" = "#BDBDBD" #NA
        ),
        
        labels = c(
          "0" = "0",
          "1" = "1",
          "2" = "2",
          "3" = "3",
          "4" = "4",
          "5" = "5",
          "6" = "Not updated outside of core drought season"
        ),
        name = "Drought Levels",
      ) +
      
      labs(
        x = "",
        y = ""
      )+
      
      theme_minimal() +
      
      scale_x_discrete(position = "top") +
      
      theme(
        axis.text.x = element_text(
          angle = 30,
          hjust = 0.5,
          size = 14,
        ),
        
        axis.text.x.bottom = element_blank(),
        axis.ticks.x.bottom = element_blank(),
        
        
        axis.text.y = element_text(
          size = 14,
          hjust = 1
        ),
        
         
        
        panel.grid = element_blank(),
        
        legend.position = "top",
        legend.direction = "horizontal",
        
        
        legend.title = element_text(
          face = "bold",
          size = 14
        ),
        
        legend.text = element_text(
          size = 14
        )
        
      )
  })
  
  #DAILY MEAN LEVEL OF OKANAGAN LAKE PAST 5 YEARS
  output$DailyMeanPast5YearsPlot <- renderPlot({
    
    df_daily_5years <- df_daily_mean |>
      filter(Year >= max(Year) -4) 

    ggplot(df_daily_5years, 
           aes(x = DayOfYear,
               y = LEVEL, 
               group = factor(Year), 
               color = factor(Year)
               )
           ) +
      
      geom_line(linewidth = 1.5) +
      
      labs(
        x = "Month",
        y = "Mean Water Level (m, assumed datum)",
        color = "Year"
      ) +
      
      scale_x_continuous(
        breaks = c(1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335),
        labels = month.abb,
        expand = c(0, 0)
      ) +
      
      scale_y_continuous(
        breaks = scales::breaks_pretty(10)) +
      
      scale_colour_manual(
        values =  c("#D11B4A",  # 0
                    "#F6BC1A",  # 1
                    "#76ACA9",  # 2
                    "#BCB49E",  # 3
                    "#4D4d4F" ) # 4
      ) +
      
      theme(plot.title = element_text(face = 'bold'), axis.title = element_text(size = 22), axis.text = element_text(size = 16),
            legend.title = element_text(size = 18), legend.text =  element_text(size = 16))
  })
  
  #HISTORICAL RANGE FOR DAILY MEAN LAKE LEVEL LINE CHART
  output$HistoricalDailyPlot <- renderPlot({
    
    df_daily_historic <- df_daily_mean |>
      filter(Year >= min(Year),
             Year <= max(Year) -1) |>
      group_by(DayOfYear) |>
      summarise(
        Historic_Min = min(LEVEL, na.rm = TRUE),
        Historic_Max = max(LEVEL, na.rm = TRUE),
        Historic_Mean = mean(LEVEL, na.rm = TRUE)
      )
    
    df_current_year <- df_daily_mean |>
      filter(Year == max(Year))
    
    hist_color <- paste0("Historic Range ", min(df_daily_mean$Year), "-",  max(df_daily_mean$Year) -1)
    current_year <- max(df_current_year$Year)
    current_year_color <- paste0("Recent Year: ", current_year)
    
    ggplot() +
      
      geom_ribbon(data = df_daily_historic,
                  aes(x = DayOfYear, ymin = Historic_Min, ymax = Historic_Max, fill = hist_color)) +
      
      geom_line(data = df_current_year, aes(x = DayOfYear, y = LEVEL, colour = "Recent Year"),
                linewidth = 1.5) + 
      
      geom_line(data = df_daily_historic, 
                aes(x = DayOfYear, y = Historic_Mean, colour = "Historic Daily Mean"), linewidth = 1.5) +
      
      labs(
        x = "Month",
        y = "Daily Mean Water Level (m, assumed datum)"
      ) +
      
      scale_x_continuous(
        breaks = c(1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335),
        labels = month.abb,
        expand = c(0, 0)
      ) +
      
      scale_y_continuous(
        breaks = scales::breaks_pretty(10)) +
      
      scale_fill_manual(
        values = "gray80",
        name = ""
      ) +
      
      scale_colour_manual(
        values = c("Historic Daily Mean" ="#76ACA9", "Recent Year" = "#D11B4A"),
        labels = c("Historic Daily Mean", current_year_color),
        name = NULL
      ) +
      
      theme(plot.title = element_text(face = 'bold'), axis.title = element_text(size = 22), axis.text = element_text(size = 16),
            legend.title = element_text(size = 18), legend.text =  element_text(size = 16))
  })
  
  #DAILY MEAN LEVEL OF OKANAGAN LAKE LINE CHART
  output$DailyMeanLevelPlot <- renderPlot({
    
    filtered_df_daily_mean <- df_daily_mean |>
      dplyr::filter(year(DATE) %in% input$levelyear)
    
    ggplot(filtered_df_daily_mean, aes(x = DayOfYear, y = LEVEL)) +
      geom_line(color = "#76ACA9", linewidth = 1.5) +
      
      labs(x = "Month", y = "Mean Daily Water Level (m, assumed datum)") + 
      
      scale_x_continuous(
        breaks = c(1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335),
        labels = month.abb,
        expand = c(0, 0)
      ) +
      
      scale_y_continuous(
        breaks = scales::breaks_pretty(10)) +
      
      theme(plot.title = element_text(face = 'bold'), axis.title = element_text(size = 22), axis.text = element_text(size = 16))
  })
  
  #STREAM THERMAL STATE BAR CHART
  output$StreamStatePlot <- renderPlot({
    
    df_stream_7day <- df_stream_temp |>
      mutate(date = as.Date(date)) |>
      group_by(station) |>
      slice_max(order_by = date, n = 7) |>
      summarise(
        water_temp = mean(water_temp, na.rm = TRUE),
        start_date = min(date),
        end_date = max(date),
        .groups = "drop"
      )
    
    df_stream_7day <- df_stream_7day |>
      mutate(
        station = reorder(station, water_temp)
      )
    
    df_stream_7day <- drop_na(df_stream_7day, water_temp)

    date_range <- paste0(
      format(min(df_stream_7day$start_date), "%b %d, %Y"),
      " – ",
      format(max(df_stream_7day$end_date), "%b %d, %Y")
    )

    ggplot(df_stream_7day, aes(x = water_temp, y = station))+
      geom_col(aes(fill = ifelse(water_temp >= 21, "above", "below")), linewidth = 1) +
      
      geom_vline(
        aes(xintercept = 21,
        colour = "19-21°C threshold"),
        linewidth = 1,
        linetype = "dashed"
      ) +
      
      geom_vline(
        xintercept = 19,
        colour = "black",
        linewidth = 1,
        linetype = "dashed"
      ) +
      
      scale_fill_manual(
        name = NULL,
        values = c(
          "above" = "#D11B4A",
          "below" = "#76ACA9"
        ),
        labels = c(
          "above" = "≥ 21°C",
          "below" = "< 21°C"
        )
      ) +
      
      # Threshold colours
      scale_colour_manual(
        name = NULL,
        values = c(
          "19-21°C threshold" = "black"
        )
      ) +
      
      scale_x_continuous(
        labels = function(x) paste0(x, " C"),
        expand = expansion(mult = c(0, 0.05))
        )+

      labs(
        x = paste0(
          "7-day mean water temperature (", date_range, ")"),
        y = "Station"
      )+ 
      
      theme(plot.title = element_text(face = 'bold'), axis.title = element_text(size = 22), axis.text = element_text(size = 16),
            legend.title = element_text(size = 18), legend.text =  element_text(size = 16))
  })
  
  #CLICKABLE LINKS ON HOME PAGE
  observeEvent(input$net_inflow_link, {
    updateTabItems(session, "tabs", "net_inflow")
  })
  
  observeEvent(input$water_consumption_link, {
    updateTabItems(session, "tabs", "water_consumption")
  })
  
  observeEvent(input$lake_level_link, {
    updateTabItems(session, "tabs", "mean_daily_level")
  })
  
  observeEvent(input$groundwater_link, {
    updateTabItems(session, "tabs", "groundwater_wells")
  })
  
  observeEvent(input$drought_link, {
    updateTabItems(session, "tabs", "drought_level")
  })
  
  observeEvent(input$stream_state_link, {
    updateTabItems(session, "tabs", "stream")
  })
  
}
