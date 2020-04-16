library(shiny)
library(shinyWidgets)
library(leaflet)

# EXAMPLE LOCATIONS TO USE IN THE MENU
examples <- c(
  "Continent view" = "SSA",
  "Western Kenya" = "W_KE",
  "Southern Nigeria" = "S_NI",
  "Rwanda" = "RW"
)

# MAIN PAGE 
navbarPage("Acidic Soils in Sub-Saharan Africa", id="main",
           tabPanel("Map",
                    leafletOutput("acidmap", height=850),
                    # Shiny versions prior to 0.11 should use class = "modal" instead.
                    absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                  top = 100, left = "auto", right = 10, bottom = 100,  #padding from windows
                                  width = 450, height = "auto",
                                  h3("Soil acidity in Sub-Saharan Africa croplands"),
                                  h5("Acid soils cover more than a third of Sub-Saharan Africa affecting the livelihoods of 80% of the rural population."),
                                  div(class = "selected_country", textOutput("selected_country")),
                                  plotOutput("cropland_plot", height = 200),
                                  plotOutput("pop_plot", height = 200),
                                  selectInput(inputId="location",label="Visit Example Locations", choices=examples, selected = "SSA"),
                                  tags$a(tags$img(src="CIMMYTlogo.png", height="5%", align = "center", href="www.cimmyt.org"),href="https://www.cimmyt.org"),
                                  tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),  #stylesheet
                                  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),   #for the map
                                  includeHTML("notes.html")  #notes at the bottom of the panel
                    )),
           tabPanel("Country summary",
                    sidebarLayout(
                      sidebarPanel(
                        pickerInput(inputId = "country_select", label = "Country: ",
                                    choices = country_names_list_noSSA,
                                    selected = c("KE")
                        ),
                        pickerInput(inputId = "type_select", label = "Type to show: ",
                                    choices = types_names_list,
                                    selected = c("Area")
                        )
                        
                      ),
                      
                      mainPanel(plotOutput("crop_area_country"))
                    )
           ),
           tabPanel("Data",
                    DTOutput("acid_crops_summary_bycountry_table", width = "60%"),
                    downloadButton("downloadData", "Download all data")
           ),
           tabPanel("Read Me",includeMarkdown("readme.md"))
)
