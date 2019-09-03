library(leaflet)

#Example locations to zoom and coordinates
examples <- c(
  "Continent view" = "SSA",
  "Western Kenya" = "W_KE",
  "Southern Nigeria" = "S_NI",
  "Rwanda" = "RW"
)

navbarPage("Explorer of soil acidity in SSA croplands", id="nav",
           #img(src="CIMMYTlogo.png", style="float:right; padding-right:25px"),
           
           #### The top panel ####
           tabPanel(title = "Interactive map",
                    div(class="outer",
                        tags$head(
                          # Include our custom CSS
                          includeCSS("styles.css"),
                          includeScript("gomap.js")
                        ),
                        
                        #### The interactive Map ####
                        # If not using custom CSS, set height of leafletOutput to a number instead of percent
                        leafletOutput(outputId = "map", width="100%", height="100%"),
                        
                        # Shiny versions prior to 0.11 should use class = "modal" instead.
                        absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                      draggable = FALSE, top = 60, left = "auto", right = 20, bottom = 20,
                                      width = 450, height = "auto",
                                      h3("Explorer of soil acidity in SSA croplands"),
                                      h5("Acid soils cover more than a third of Subsaharan Africa, affecting agricultural productivity"),
                                      div(class = "selected_country", textOutput("selected_country")),
                                      plotOutput("cropland_plot", height = 200),
                                      plotOutput("pop_plot", height = 200),
                                      selectInput(inputId="location",label="Visit Example Locations", choices=examples, selected = "SSA"),
                                      tags$a(tags$img(src="CIMMYTlogo.png", height="5%", align = "center", href="www.cimmyt.org"),href="https://www.cimmyt.org"),
                                      includeHTML("notes.html")  #notes at the bottom of the panel
                        )
                    )
           ),
           tabPanel(title = "dumb"),
                    
           conditionalPanel("false", icon("crosshair"))
)