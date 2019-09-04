library(leaflet)

#Example locations to zoom and coordinates
examples <- c(
  "Continent view" = "SSA",
  "Western Kenya" = "W_KE",
  "Southern Nigeria" = "S_NI",
  "Rwanda" = "RW"
)

bootstrapPage(
  tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),  #stylesheet
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),   #for the map
  
  leafletOutput(outputId = "map", width="100%", height="100%"),
  
  # Shiny versions prior to 0.11 should use class = "modal" instead.
  absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                top = 10, left = "auto", right = 10, bottom = 0,  #padding from window
                width = 450, height = "auto",
                h3("Soil acidity in sub-Saharan Africa croplands"),
                h5("Acid soils cover more than a third of Subsaharan Africa affecting the livelihoods of 80% of the rural population."),
                div(class = "selected_country", textOutput("selected_country")),
                plotOutput("cropland_plot", height = 200),
                plotOutput("pop_plot", height = 200),
                selectInput(inputId="location",label="Visit Example Locations", choices=examples, selected = "SSA"),
                tags$a(tags$img(src="CIMMYTlogo.png", height="5%", align = "center", href="www.cimmyt.org"),href="https://www.cimmyt.org"),
                includeHTML("notes.html")  #notes at the bottom of the panel
  )
)