library(shiny)
library(RColorBrewer)
library(scales)
library(tidyverse)
library(leaflet)
library(DT)


# SSA Shapefile definition ###########################################
SSA_level0 <- geojsonio::geojson_read(x = "data/gadm36_0_simplified.geojson", what = 'sp')
SSA_level1 <- geojsonio::geojson_read(x = "data/gadm36_1_simplified.geojson", what = 'sp')

# Colors for plotting ###########################################
mycols <- c("#FF6B00", "#F7A84D", "#EEE49A", "#A77A6D", '#5F0F40')

#Coordinate examples 
examples_coordinates <- data.frame(ISO3166_1 = c("SSA", "W_KE", "S_NI", "RW"),
                                   lat = c(-7, -0.27, 4.63, -2.08),
                                   long = c(20, 34.51, 7.84, 29.72),
                                   zoom = c(4, 8,8,8))

#Color factor for legend
myfactors <- data.frame(labels = c("Highly acidic (<5.6)", "Slightly acidic (5.6-6.5)", "Optimal (6.6-7.3)", "Slightly alkaline (7.4-7.8)", "Highly alkaline (>7.8)"),
                        labels2 = c("Highly acidic", "Slightly acidic", "Optimal", "Slightly alkaline", "Highly alkaline"),
                        ranges = c("<5.6", "5.6-6.5", "6.6-7.3", "7.4-7.8", ">7.8"))
myfactors$labels <- factor(myfactors$labels, levels = c("Highly acidic (<5.6)", "Slightly acidic (5.6-6.5)", "Optimal (6.6-7.3)", "Slightly alkaline (7.4-7.8)", "Highly alkaline (>7.8)"))
qpal <- colorFactor(palette = mycols, domain = myfactors$labels)


shinyServer(function(input, output, session) {
  
  # create a color paletter for category type in the data file
  output$acidmap <- renderLeaflet({
    leaflet(SSA_level0,
            options = leafletOptions(zoomControl = FALSE, minZoom = 4, maxZoom = 10)) %>%
      addTiles(group = "CartoDB") %>% 
      addProviderTiles(providers$CartoDB.Positron, group = "Map") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
      addTiles(urlTemplate = "https://storage.googleapis.com/acidsoils-ssa/ph_cropland_class/{z}/{x}/{y}",  #
               attribution = '&copy; <a href="http://www.cimmyt.org/">CIMMYT</a>',
               group = "Soil Acidity") %>%
      addPolygons(layerId=~ISO3166_1,
                  color = "#55565A", weight = 0.5,
                  fillColor = "#FFFFFF",
                  opacity = 0.5,
                  label = ~paste0(ISO3166_1),  #what to show 
                  highlightOptions = highlightOptions(color = "#FF6B00", weight = 2,
                                                      bringToFront = TRUE)) %>%  #starting view
      addLegend("bottomleft", pal = qpal, values = myfactors$labels, title = "pH level", opacity = 1) %>% 
      addMiniMap(tiles = providers$CartoDB.Positron, position = "topleft") %>% 
      addLayersControl(
        baseGroups = c("Map", "Satellite"),
        overlayGroups = c("Soil Acidity"),
        options = layersControlOptions(collapsed = FALSE),
        position = "topleft")
  })
  
  
  # A reactive expression that returns the coordinates of the selected example location
  center <- reactive({
    subset(examples_coordinates, ISO3166_1 == input$location) 
  })
  
  # set the new coordinates to the coorindates for that center
  observe({
    leafletProxy('acidmap') %>% 
      setView(lng =  center()$long, lat = center()$lat, zoom = center()$zoom)
  })
  
  #Observing click event on map (See that map_shape_click is sensitive to the name of the map. In this case is "map". Naming it Map would require Map_click_event)
  observeEvent(eventExpr = input$acidmap_shape_click, {
    selected_ISO3166_1 <- input$acidmap_shape_click$`id`
    #print(selected_ISO3166_1)
  })
  
  
  ## Country name to show ###########################################
  output$selected_country <- renderText({
    if (length(input$acidmap_shape_click$`id`) == 0){
      selected_ISO3166_1 <- "SSA"  #default value
    } else {
      selected_ISO3166_1 <- input$acidmap_shape_click$`id`
    }
    country_names[country_names$ISO3166_1 == selected_ISO3166_1, "country_na"] %>% as.character()
  })
  
  
  
  ## Crop areas chart ###########################################
  output$cropland_plot <- renderPlot({
    #Subsetting data to selected country
    if (length(input$acidmap_shape_click$`id`) == 0){
      selected_ISO3166_1 <- "SSA"  #default value
    } else {
      selected_ISO3166_1 <- input$acidmap_shape_click$`id`
    }
    cropareas_country <- cropareas %>% filter(ISO3166_1 == selected_ISO3166_1)
    croparea_country <- sum(cropareas_country$area_km)
    
    #Creating plot
    ggplot(cropareas_country, aes(x = ph_class, y = area_km, fill = ph_class)) +
      geom_bar(width = 1, stat = "identity") +
      geom_text(data = cropareas_country,
                aes(x = ph_class, y = area_km,
                    label = paste0(comma(round(area_km))," (", percent(area_km/croparea_country), ")"),
                    hjust=ifelse(area_km < max(`area_km`) / 1.5, -0.1, 1.1)),
                color = "#55565A", )+
      scale_fill_manual(values = mycols) +
      scale_x_discrete(labels = myfactors$labels2) + 
      scale_y_continuous(labels = comma) + 
      ggtitle('Cropland area') + ylab(expression(Area ~ (km^2))) + xlab("") +
      theme_minimal() + 
      theme(plot.title = element_text(colour = "#55565A", size=14),
            panel.grid.major.y = element_blank(),
            panel.grid.minor.y = element_blank(),
            legend.position = "none") +
      coord_flip()
  })
  
  ## Population pie chart ###########################################
  output$pop_plot <- renderPlot({
    #Subsetting data to selected country
    if (length(input$acidmap_shape_click$`id`) == 0){
      selected_ISO3166_1 <- "SSA"  #default value
    } else {
      selected_ISO3166_1 <- input$acidmap_shape_click$`id`
    }
    pops_country <- population %>% filter(ISO3166_1 == selected_ISO3166_1) %>% filter(ph_class !="SSApop")
    pop_country <- sum(pops_country$population)
    
    #Creating plot
    ggplot(pops_country, aes(x = ph_class, y = population, fill = ph_class)) +
      geom_bar(width = 1, stat = "identity", alpha = 0.4) +
      geom_text(data = pops_country,
                aes(x = ph_class, y = population,
                    label = paste0(comma(population)," (", percent(population/pop_country), ")"),
                    hjust=ifelse(population < max(`population`) / 1.5, -0.1, 1.1)),
                color = "#55565A", ) +
      scale_fill_manual(values = mycols) +
      scale_x_discrete(labels = myfactors$labels2) + 
      scale_y_continuous(labels = comma) + 
      ggtitle('Rural population') + ylab(expression(Population)) + xlab("") +
      theme_minimal() + 
      theme(plot.title = element_text(colour = "#55565A", size=14),
            panel.grid.major.y = element_blank(),
            panel.grid.minor.y = element_blank(),
            legend.position = "none") +
      coord_flip()
  })
  
  ## Specific crop|country areas chart ###########################################
  output$acid_crops_summary_bycountry_table <- renderDT(acid_crops_summary_bycountry,
                                                        filter="top",
                                                        options=list(pageLength=10))
    
  
  ## Specific crop|country areas chart ###########################################
  output$crop_area_country <- renderPlot({
    #Subsetting data to selected country
    acid_crops_summary_country_type <- acid_crops_summary_bycountry %>% filter(ISO3166_1 == input$country_select & Type  == input$type_select)
    #acid_crops_summary_country_type <- acid_crops_summary_bycountry %>% filter(ISO3166_1 == "NG" & Type  == "Area")
    
    #removing factors if there isn't any area
    #crops_in <- as.character(acid_crops_summary_country_type$Crop[(acid_crops_summary_country_type %>% filter(pH_type == "All"))$value == 0])
    #acid_crops_summary_country_type <- acid_crops_summary_country_type %>% filter(Crop %in% crops_in)
    #acid_crops_summary_country_type$Crop <- factor(acid_crops_summary_country_type$Crop , levels = crops_in)
    
    # Labels to use
    if (input$type_select == "Area"){
      axis_label <- "Area (km2)"
      title_label <- "Area"
    } else {
      axis_label <- "Production (MT)"
      title_label <- "Production"
    }
    
    country_name <- country_names[country_names$ISO3166_1 == input$country_select,]$country_na
    #country_name <- "Intento"
    
    #Creating plot
    ggplot(acid_crops_summary_country_type, aes(x = Crop, y = value, fill = pH_type)) +
      geom_bar(width = 0.7, stat = "identity", position = "identity") +
      geom_text(aes(x = Crop, y = value,
                    label = percent(prop)),
                    #hjust=ifelse(area_km < max(`area_km`) / 1.5, -0.1, 1.1)),
                colour = "black")+
      scale_fill_manual(values = mycols) +
      #scale_x_discrete(labels = myfactors$labels2) + 
      #scale_y_continuous(labels = comma) + 
      ggtitle(paste0(country_name, ': ', title_label)) +
      ylab(axis_label) + xlab("") +
      theme_minimal() + 
      theme(plot.title = element_text(colour = "#55565A", size=14),
            panel.grid.major.y = element_blank(),
            panel.grid.minor.y = element_blank(),
            legend.position = "none") +
      coord_flip()
  })
  
  ## Download data handler ###########################################
  output$downloadData <- downloadHandler(filename = "acid_crops_summary_bycountry.csv",
                                         content = function(file) {
                                           write.csv(acid_crops_summary_bycountry, file, row.names = FALSE)
                                         })
  
  
})