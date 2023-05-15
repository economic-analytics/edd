ons_process_rgva <- function(filepath = NULL, build_for_edd = TRUE) {

  if (is.null(filepath)) {
    filepath <- "data-raw/regionalgrossvalueaddedbalancedbyindustryandallitlregions.xlsx"
  }

  rgva_sheets <- readxl::excel_sheets(filepath)[grepl("Table", readxl::excel_sheets(filepath))]

  rgva <- lapply(rgva_sheets, function(sht) {
    readxl::read_excel(path = filepath,
                       sheet = sht,
                       skip = 1,
                       na = "u")
    }) |>
    setNames(c("ITL1_cvm", "ITL1_constant", "ITL1_current", "ITL1_deflators",
               "ITL2_cvm", "ITL2_constant", "ITL2_current", "ITL2_deflators",
               "ITL3_cvm", "ITL3_constant", "ITL3_current", "ITL3_deflators"))

  # Set variable names of all dfs to that of the first
  rgva <- lapply(rgva, function(df) setNames(df, names(rgva[[1]])))

  # get rid of any footnote rows at the bottom of each table
  rgva <- lapply(rgva, function(df) dplyr::filter(df, !is.na(`SIC07 code`)))

  # pivots dates to single column
  rgva <- lapply(rgva, function(df) tidyr::pivot_longer(df, cols = -(1:4), names_to = "dates"))

  rgva <- rgva |>
    dplyr::bind_rows(.id = "variable") |>
    tidyr::separate(col  = "variable",
                    into = c("geography_type", "variable"),
                    sep  = "_") |>
    dplyr::rename(geography_code  = `ITL region code`,
                  geography_name  = `ITL region name`,
                  industry_code = `SIC07 code`,
                  industry_name = `SIC07 description`) |>
    # removes any superscript notes at the end of dates
    dplyr::mutate(dates = stringr::str_sub(dates, 1, 4),
                  dates = tibble::tibble(date = as.Date(paste0(dates, "-01-01")),
                                         freq = "a"),
                  # if industry_code is single digit, add a leading zero
                  industry_code = dplyr::case_when(
                    grepl("[0-9]", industry_code) &
                      stringr::str_length(industry_code) == 1 ~
                      paste0("0", industry_code),
                    TRUE ~ industry_code),
                  geography_type = dplyr::case_when(geography_code == "UK"  ~ "ctry",
                                                    geography_code == "TLB" ~ "ctry",
                                                    TRUE ~ geography_type)) |>
    dplyr::select(dates,
                  geography_type, geography_code, geography_name,
                  industry_code, industry_name,
                  variable,
                  value)

  readr::write_csv(jsonlite::flatten(rgva), "data-raw/rgva.csv")

  if (build_for_fedo) {
    ons_rgva_to_fedo(rgva)
  } else {
    return(rgva)
  }
}

ons_rgva_to_fedo <- function(rgva) { # takes the processed rgva file

  variable <- rgva |>
    dplyr::select(code = variable) |>
    dplyr::mutate(name = dplyr::case_when(code == "cvm"       ~ "CVM Index",
                                          code == "constant"  ~ "Constant prices",
                                          code == "current"   ~ "Current prices",
                                          code == "deflators" ~ "Implied deflator",
                                          TRUE                ~ code),
                  unit = dplyr::case_when(code == "cvm"       ~ "2019 = 100",
                                          code == "constant"  ~ "2019 £m",
                                          code == "current"   ~ "£m",
                                          code == "deflators" ~ "2019 = 100",
                                          TRUE                ~ code)) |>
    dplyr::distinct()

  geography <- rgva |>
    dplyr::select(code = geography_code,
                  name = geography_name,
                  type = geography_type) |>
    dplyr::distinct() |>
    dplyr::mutate(type = dplyr::case_when(!is.na(type) ~ paste0(tolower(type), "21"),
                                          TRUE ~ type))

  industry <- rgva |>
    dplyr::select(code = industry_code,
                  name = industry_name) |>
    dplyr::mutate(type = "SIC2007") |>
    dplyr::distinct()

  dimensions <- list(variable  = variable,
                     geography = geography,
                     industry  = industry)

  data <- rgva |>
    dplyr::select(dates,
                  geography = geography_code,
                  industry  = industry_code,
                  variable,
                  value)

  rgva_final <- list(data       = data,
                     dimensions = dimensions)

  readr::write_rds(rgva_final, "data/datasets/RGVA.rds")

  return(rgva_final)

}
