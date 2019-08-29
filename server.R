library(leaflet)
library(RColorBrewer)
library(scales)
library(tidyverse)
#library(geojsonio)   #to deal with the geojson map file


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
    leaflet(SSAgeojson) %>%
      addTiles(urlTemplate = "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",  #
               attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>') %>% 
      addTiles(urlTemplate = "https://storage.googleapis.com/acidsoils-ssa/acidsoils2Blended/{z}/{x}/{y}",  #
               attribution = '&copy; <a href="http://www.cimmyt.org/">CIMMYT</a>') %>%
      addPolygons(layerId=~country_co,
                  color = "#55565A",
                  weight = 0.5,
                  fillColor = "#FFFFFF",
                  opacity = 0.5,
                  label = ~paste0(country_na),  #what to show 
                  highlightOptions = highlightOptions(color = "#FF6B00",
                                                      weight = 2,
                                                      bringToFront = TRUE)) %>%  #starting view
      addLegend("bottomleft", pal = qpal, values = myfactors$labels, title = "pH level", opacity = 1)
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
      ggtitle('Population') + ylab(expression(Population)) + xlab("") +
      theme_minimal() + 
      theme(plot.title = element_text(colour = "#55565A", size=14),
            panel.grid.major.y = element_blank(),
            panel.grid.minor.y = element_blank(),
            legend.position = "none") +
      coord_flip()
  })
  
  # output$scatterCollegeIncome <- renderPlot({
  #   # If no zipcodes are in view, don't plot
  #   if (nrow(zipsInBounds()) == 0)
  #     return(NULL)
  #   print(xyplot(income ~ college, data = zipsInBounds(), xlim = range(allzips$college), ylim = range(allzips$income)))
  # })
  # 
  # This observer is responsible for maintaining the circles and legend,
  # according to the variables the user has chosen to map to color and size.
  # observe({
  #   colorBy <- input$color
  #   
  #   if (colorBy == "superzip") {
  #     # Color and palette are treated specially in the "superzip" case, because
  #     # the values are categorical instead of continuous.
  #     colorData <- ifelse(zipdata$centile >= (100 - input$threshold), "yes", "no")
  #     pal <- colorFactor("viridis", colorData)
  #   } else {
  #     colorData <- zipdata[[colorBy]]
  #     pal <- colorBin(palette = "viridis", domain = colorData, 7, pretty = FALSE)
  #   }
  #   
  #   leafletProxy(mapId = "map", data = zipdata) %>%
  #     clearShapes() %>%
  #     addCircles(~longitude, ~latitude, radius=1, layerId=~zipcode,
  #                stroke=FALSE, fillOpacity=0.4, fillColor=pal(colorData)) %>%
  #     addLegend("bottomleft", pal=pal, values=colorData, title=colorBy,
  #               layerId="colorLegend")
  # })
  
  # Show a popup at the given location
  # showZipcodePopup <- function(zipcode, lat, lng) {
  #   selectedZip <- allzips[allzips$zipcode == zipcode,]
  #   content <- as.character(tagList(
  #     tags$h4("Score:", as.integer(selectedZip$centile)),
  #     tags$strong(HTML(sprintf("%s, %s %s",
  #                              selectedZip$city.x, selectedZip$state.x, selectedZip$zipcode
  #     ))), tags$br(),
  #     sprintf("Median household income: %s", dollar(selectedZip$income * 1000)), tags$br(),
  #     sprintf("Percent of adults with BA: %s%%", as.integer(selectedZip$college)), tags$br(),
  #     sprintf("Adult population: %s", selectedZip$adultpop)
  #   ))
  #   leafletProxy("map") %>% addPopups(lng, lat, content, layerId = zipcode)
  # }
  
  # When map is clicked, show a popup with city info
  # observe({
  #   leafletProxy("map") %>% clearPopups()
  #   event <- input$map_shape_click
  #   if (is.null(event))
  #     return()
  #   
  #   isolate({
  #     showZipcodePopup(event$id, event$lat, event$lng)
  #   })
  # })
  
  
  # ## Data Explorer ###########################################
  # observe({
  #   cities <- if (is.null(input$states)) character(0) else {
  #     filter(cleantable, State %in% input$states) %>%
  #       `$`('City') %>%
  #       unique() %>%
  #       sort()
  #   }
  #   stillSelected <- isolate(input$cities[input$cities %in% cities])
  #   updateSelectInput(session, "cities", choices = cities,
  #                     selected = stillSelected)
  # })
  # 
  # observe({
  #   zipcodes <- if (is.null(input$states)) character(0) else {
  #     cleantable %>%
  #       filter(State %in% input$states,
  #              is.null(input$cities) | City %in% input$cities) %>%
  #       `$`('Zipcode') %>%
  #       unique() %>%
  #       sort()
  #   }
  #   stillSelected <- isolate(input$zipcodes[input$zipcodes %in% zipcodes])
  #   updateSelectInput(session, "zipcodes", choices = zipcodes,
  #                     selected = stillSelected)
  # })
  # 
  # observe({
  #   if (is.null(input$goto))
  #     return()
  #   isolate({
  #     map <- leafletProxy("map")
  #     map %>% clearPopups()
  #     dist <- 0.5
  #     zip <- input$goto$zip
  #     lat <- input$goto$lat
  #     lng <- input$goto$lng
  #     showZipcodePopup(zip, lat, lng)
  #     map %>% fitBounds(lng - dist, lat - dist, lng + dist, lat + dist)
  #   })
  # })
  # 
  # output$ziptable <- DT::renderDataTable({
  #   df <- cleantable %>%
  #     filter(
  #       Score >= input$minScore,
  #       Score <= input$maxScore,
  #       is.null(input$states) | State %in% input$states,
  #       is.null(input$cities) | City %in% input$cities,
  #       is.null(input$zipcodes) | Zipcode %in% input$zipcodes
  #     ) %>%
  #     mutate(Action = paste('<a class="go-map" href="" data-lat="', Lat, '" data-long="', Long, '" data-zip="', Zipcode, '"><i class="fa fa-crosshairs"></i></a>', sep=""))
  #   action <- DT::dataTableAjax(session, df)
  #   
  #   DT::datatable(df, options = list(ajax = list(url = action)), escape = FALSE)
  # })
}