# objects available to both ui.R and server.R

allcountries <- readRDS("data/country_results.rds")
#str(allcountries)

#Example locations to zoom and coordinates
examples <- c(
  "sub-Saharan Africa" = "SSA",
  "Western Kenya" = "W_KE",
  "Southern Nigeria" = "S_NI",
  "Rwanda, Uganda, Congo" = "RUC"
)

examples_coordinates <- data.frame(country_co = c("SSA", "W_KE", "S_NI", "RUC"),
                                   lat = c(-10, 1.4, 11, -2),
                                   long = c(20, 35.3, 7.5, 33),
                                   zoom = c(3, 8,8,7))
