# utils-geocodes

add_geography_type <- function(df, geography_code = "geography_code") {

  # import register of geographic codes
  rgc_files <- list.files("data-raw", pattern = "Register_of_Geographic_Codes",
                          full.names = TRUE)

  if (length(rgc_files) > 1) {
    message("More than one Register of Geographic Codes found in `data-raw`.")
    print(basename(rgc_files))
    rgc_choice <- readline("Which one do you want to use? (Enter number)\n") |>
      as.integer()
  } else {
    rgc_choice <- 1
  }
  rgc <- readr::read_csv(rgc_files[rgc_choice],
                         show_col_types = FALSE)
  df$geography_type <- rgc$`Entity abbreviation`[
    rgc$`Entity code` == substr(df[[geography_code]], 1, 3)]

  return(df)
}

# tests -------------------------------------------------------------------

# df <- data.frame(geography_code = "E08000003")
# add_geography_type(df)
