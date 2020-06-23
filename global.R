# OBJECTS AVAILABLE TO ui.r and server.r

# tables in use  ###########################################
country_names <- read.csv("data/country_names.csv", na.strings = "nan")  #country names to use in plots
cropareas <- read.csv("data/cropareas.csv")  #crop areas per pH class. see acidsoils repository: acidsoils_summary.Rmd
population <- read.csv("data/population.csv")  #population per pH class. see acidsoils repository: acidsoils_summary.Rmd
crops_names_list <- c("Barley" = "BARL",
                      "Maize" = "MAIZ",
                      "Rice" = "RICE")
types_names_list <- c("Area" = "Area",
                      "Production" = "Prod")

#country-specific information table
acid_crops_summary_bycountry <- read.csv("data/acid_crops_summary_bycountry.csv")

#Creating named list of country names to use in menus
country_names_list <- as.character(country_names$ISO3166_1)
names(country_names_list) <- country_names$country_na

country_names_list_noSSA <- country_names_list[1:(length(country_names_list)-1)]
