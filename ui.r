library(leaflet)

# Choices for drop-downs
vars <- c(
  "Is SuperZIP?" = "superzip",
  "Centile score" = "centile",
  "College education" = "college",
  "Median income" = "income",
  "Population" = "adultpop"
)


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
                                      h5("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Dolor sed viverra ipsum nunc aliquet bibendum enim. In massa tempor nec feugiat. Nunc aliquet bibendum enim facilisis gravida. Nisl nunc mi ipsum faucibus vitae aliquet nec ullamcorper. Amet luctus venenatis lectus magna fringilla. Volutpat maecenas volutpat blandit aliquam etiam erat velit scelerisque in."),
                                      div(class = "selected_country", textOutput("selected_country")),
                                      plotOutput("cropland_plot", height = 200),
                                      plotOutput("pop_plot", height = 200),
                                      selectInput(inputId="location",label="Visit Example Locations", choices=examples, selected = "SSA"),
                                      tags$a(tags$img(src="CIMMYTlogo.png", height="05%", align = "center", href="www.cimmyt.org"),href="https://www.cimmyt.org"),
                                      h6("Data compiled for the Soils in Sub-Saharan Africa Project by Sebastian Palmas. For more information see ", tags$a(href="https://www.cimmyt.org", "CIMMYT"))
                        )
                        
                    )
           ),
           # 
           # tabPanel("Data explorer",
           #          fluidRow(
           #            column(3,
           #                   selectInput("states", "States", c("All states"="", structure(state.abb, names=state.name), "Washington, DC"="DC"), multiple=TRUE)),
           #            column(3,
           #                   conditionalPanel("input.states",
           #                                    selectInput("cities", "Cities", c("All cities"=""), multiple=TRUE))),
           #            column(3,
           #                   conditionalPanel("input.states",
           #                                    selectInput("zipcodes", "Zipcodes", c("All zipcodes"=""), multiple=TRUE)))
           #          ),
           #          fluidRow(
           #            column(1,
           #                   numericInput("minScore", "Min score", min=0, max=100, value=0)
           #            ),
           #            column(1,
           #                   numericInput("maxScore", "Max score", min=0, max=100, value=100)
           #            )
           #          ),
           #          hr(),
           #          DT::dataTableOutput("ziptable")
           # ),
           
           conditionalPanel("false", icon("crosshair"))
)