library(leaflet)
library(RColorBrewer)
library(scales)
library(tidyverse)
#library(extrafont)
library(waffle)   #for pictogram
library(hrbrthemes)
library(fontawesome)
#font_import()
#loadfonts(device = "win")
#extrafont::loadfonts(device="win")


# table in use  ###########################################
cropareas <- readRDS("data/cropareas.rds")  #crop areas per pH class. see acidsoils repository
population <- readRDS("data/population.rds")
country_names <- readRDS("data/country_names.rds")  #country names  see acidsoils repository

# SSA Shapefile definition ###########################################
#SSAgeojson <- jsonlite::fromJSON("data/SSA_LSIB7a_gen_polygons.geojson")
SSAgeojson <- geojsonio::geojson_read(x = "data/SSA_LSIB7a_gen_polygons.geojson", what = 'sp')

# Colors for plotting ###########################################
mycols <- c("#FF6B00", "#F7A84D", "#EEE49A", "#A77A6D", '#5F0F40')

#Coordinate examples 
examples_coordinates <- data.frame(country_co = c("SSA", "W_KE", "S_NI", "RW"),
                                   lat = c(-7, -0.27, 4.63, -2.08),
                                   long = c(20, 34.51, 7.84, 29.72),
                                   zoom = c(4, 8,8,8))

#Color factor for legend
myfactors <- data.frame(labels = c("Highly acidic (<5.6)", "Slightly acidic (5.6-6.5)", "Optimal (6.6-7.3)", "Slightly alkaline (7.4-7.8)", "Highly alkaline (>7.8)"),
                        labels2 = c("Highly acidic", "Slightly acidic", "Optimal", "Slightly alkaline", "Highly alkaline"),
                        ranges = c("<5.6", "5.6-6.5", "6.6-7.3", "7.4-7.8", ">7.8"))
myfactors$labels <- factor(myfactors$labels, levels = c("Highly acidic (<5.6)", "Slightly acidic (5.6-6.5)", "Optimal (6.6-7.3)", "Slightly alkaline (7.4-7.8)", "Highly alkaline (>7.8)"))
qpal <- colorFactor(palette = mycols, domain = myfactors$labels)

#plot(SSAgeojson)
#SSAgeojson <- readOGR("data/SSA_LSIB7a_gen_polygons.geojson")

# Server function ###########################################
function(input, output, session) {
  
  ## Interactive Map ###########################################
  
  #### Create the map ####
  output$map <- renderLeaflet({
    leaflet(SSAgeojson,
            options = leafletOptions(zoomControl = FALSE, minZoom = 4, maxZoom = 10)) %>%
      addTiles(group = "CartoDB") %>% 
      addProviderTiles(providers$CartoDB.Positron, group = "Map") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
      addTiles(urlTemplate = "https://storage.googleapis.com/acidsoils-ssa/acidsoils_tiles_v2_6/{z}/{x}/{y}",  #
               attribution = '&copy; <a href="http://www.cimmyt.org/">CIMMYT</a>',
               group = "Soil Acidity") %>%
      addPolygons(layerId=~country_co,
                  color = "#55565A",
                  weight = 0.5,
                  fillColor = "#FFFFFF",
                  opacity = 0.5,
                  label = ~paste0(country_na),  #what to show 
                  highlightOptions = highlightOptions(color = "#FF6B00",
                                                      weight = 2,
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
    subset(examples_coordinates, country_co == input$location) 
  })
  
  # set the new coordinates to the coorindates for that center
  observe({
    leafletProxy('map') %>% 
      setView(lng =  center()$long, lat = center()$lat, zoom = center()$zoom)
  })
  
  #Observing click event on map (See that map_shape_click is sensitive to the name of the map. In this case is "map". Naming it Map would require Map_click_event)
  #observeEvent(eventExpr = input$map_shape_click, { 
  #  selected_country_co <- input$map_shape_click$`id`
  #  #print(selected_country_co)
  #})
  
  
  # A reactive expression that returns the set of zips that are in bounds right now
  # zipsInBounds <- reactive({
  #   if (is.null(input$map_bounds))
  #     return(zipdata[FALSE,])
  #   bounds <- input$map_bounds
  #   latRng <- range(bounds$north, bounds$south)
  #   lngRng <- range(bounds$east, bounds$west)
  #   
  #   subset(zipdata,
  #          latitude >= latRng[1] & latitude <= latRng[2] &
  #            longitude >= lngRng[1] & longitude <= lngRng[2])
  # })
  # 
  # Precalculate the breaks we'll need for the two histograms
  # centileBreaks <- hist(plot = FALSE, allzips$centile, breaks = 20)$breaks
  
  ## Country name to show ###########################################
  output$selected_country <- renderText({
    if (length(input$map_shape_click$`id`) == 0){
      selected_country_co <- "SSA"  #default value
    } else {
      selected_country_co <- input$map_shape_click$`id`
    }
    country_names[country_names$country_co == selected_country_co, "country_na"] %>% as.character()
  })
    
  ## Crop areas pie chart ###########################################
  output$cropland_plot <- renderPlot({
    #Subsetting data to selected country
    if (length(input$map_shape_click$`id`) == 0){
      selected_country_co <- "SSA"  #default value
    } else {
      selected_country_co <- input$map_shape_click$`id`
    }
    cropareas_country <- cropareas %>% filter(country_co == selected_country_co)
    croparea_country <- sum(cropareas_country$area_km)
    
    #Creating plot
    ggplot(cropareas_country, aes(x = ph_class, y = area_km, fill = ph_class)) +
      geom_bar(width = 1, stat = "identity") +
      geom_text(data = cropareas_country,
                aes(x = ph_class, y = area_km,
                    label = paste0(comma(round(area_km))," (", percent(area_km/croparea_country), ")"),
                    hjust=ifelse(area_km < max(cropareas_country$area_km) / 1.5, -0.1, 1.1)),
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
    if (length(input$map_shape_click$`id`) == 0){
      selected_country_co <- "SSA"  #default value
    } else {
      selected_country_co <- input$map_shape_click$`id`
    }
    pops_country <- population %>% filter(country_co == selected_country_co) %>% filter(ph_class !="SSApop")
    pop_country <- sum(pops_country$population)
   
    #Creating plot
    ggplot(pops_country, aes(x = ph_class, y = population, fill = ph_class)) +
      geom_bar(width = 1, stat = "identity") +
      geom_text(data = pops_country,
                aes(x = ph_class, y = population,
                    label = paste0(comma(population)," (", percent(population/pop_country), ")"),
                    hjust=ifelse(population < max(pops_country$population) / 1.5, -0.1, 1.1)),
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
}