ons_process_rgva <- function(filepath = NULL, build_for_fedo = TRUE) {

  if (is.null(filepath)) {
    filepath <- "data-raw/regionalgrossvalueaddedbalancedbyindustryallitlregions.xlsx"
  }

  rgva_sheets <- readxl::excel_sheets(filepath)
  rgva_sheets_use <- stringr::str_detect(rgva_sheets, "Table")
  rgva_sheets <- rgva_sheets[rgva_sheets_use]

  rgva <- lapply(rgva_sheets, function(sht) readxl::read_excel(path = filepath,
                                                               sheet = sht,
                                                               skip = 1,
                                                               na = "-"))
  names(rgva) <- c("NUTS1_cvm", "NUTS1_constant", "NUTS1_current", "NUTS1_deflators",
                   "NUTS2_cvm", "NUTS2_constant", "NUTS2_current", "NUTS2_deflators",
                   "NUTS3_cvm", "NUTS3_constant", "NUTS3_current", "NUTS3_deflators")

  # Set variable names of all dfs to that of the first
  rgva <- lapply(rgva, function(df) setNames(df, names(rgva[[1]])))

  # gets rid of the footnotes rows at the bottom of each table
  rgva <- lapply(rgva, function(df) dplyr::filter(df, !is.na(`SIC07 code`)))

  # pivots dates to single column
  rgva <- lapply(rgva, function(df) tidyr::pivot_longer(df, cols = -(1:4), names_to = "dates"))

  rgva <- rgva %>%
    dplyr::bind_rows(.id = "variable") %>%
    tidyr::separate(col  = "variable",
                    into = c("geog_type", "variable"),
                    sep  = "_") %>%
    dplyr::rename(geog_code  = `ITL region code`,
                  geog_name  = `ITL region name`,
                  SIC07_code = `SIC07 code`,
                  SIC07_name = `SIC07 description`) %>%
    dplyr::mutate(dates = stringr::str_sub(dates, 1, 4),
                  dates = tibble::tibble(date = as.Date(paste0(dates, "-01-01")),
                                         freq = "a"),
                  SIC07_code = dplyr::case_when(grepl("[0-9]", SIC07_code) &
                                                  stringr::str_length(SIC07_code) == 1 ~
                                                  paste0("0", SIC07_code),
                                                TRUE ~ SIC07_code),
                  geog_code = geog_code %>% str_replace("TL", "UK"),
                  geog_code = dplyr::case_when(geog_code == "UKB" ~ "UK0",
                                               TRUE ~ geog_code),
                  geog_type = dplyr::case_when(geog_code == "UK"  ~ "Country",
                                               geog_code == "UK0" ~ "Country",
                                               TRUE ~ geog_type)) %>%
    dplyr::select(dates, geog_type, geog_code, geog_name, SIC07_code, SIC07_name, variable, value)

  # England is coded as both TL0 (Tables 1a and 1b) and TLB (Tables 1c and 1d)
  # This is a hangover from NUTS codes when England was UK0
  # Trevor Fenton at ONS confirms that the new ITL system has England as TLB
  # rather than TL0

  # At time of writing we have no ITL boundary files from ONS. To deal with these
  # we've renamed all ITL codes to previous NUTS conventions (i.e. all TL to become UK,
  # UKB to become UK0. We also change types so that UK is NUTS0 and UK0 to Other)

  if (build_for_fedo) {
    ons_rgva_to_fedo(rgva)
  } else {
  return(rgva)
  }
}

ons_rgva_to_fedo <- function(rgva) { # takes the processed rgva file

  variable <- rgva %>%
    dplyr::select(code = variable) %>%
    dplyr::mutate(name = dplyr::case_when(code == "cvm"       ~ "CVM Index",
                                          code == "constant"  ~ "Constant prices",
                                          code == "current"   ~ "Current prices",
                                          code == "deflators" ~ "Implied deflator",
                                          TRUE                ~ code),
                  unit = dplyr::case_when(code == "cvm"       ~ "2018 = 100",
                                          code == "constant"  ~ "2018 £m",
                                          code == "current"   ~ "£m",
                                          code == "deflators" ~ "2018 = 100",
                                          TRUE                ~ code)) %>%
    dplyr::distinct()

  geography <- rgva %>%
    dplyr::select(code = geog_code,
                  name = geog_name,
                  type = geog_type) %>%
    dplyr::distinct() %>%
    dplyr::mutate(type = dplyr::case_when(!is.na(type) ~ paste0(tolower(type), "18"),
                                          TRUE ~ type)) # THESE ARE REALLY 2019 BOUNDARIES BUT NOT YET PUBLISHED

  industry <- rgva %>%
    dplyr::select(code = `SIC07_code`,
                  name = `SIC07_name`) %>%
    dplyr::mutate(type = "SIC07") %>%
    dplyr::distinct()

  dimensions <- list(variable  = variable,
                     geography = geography,
                     industry  = industry)

  data <- rgva %>%
    dplyr::select(dates,
                  geography = geog_code,
                  industry  = SIC07_code,
                  variable,
                  value)

  rgva_final <- list(data       = data,
                     dimensions = dimensions)

  readr::write_rds(rgva_final, "data/ons_rgva_2019.rds")

  return(rgva_final)

}


# Trial of new data shape -------------------------------------------------

# geography <- tibble::tibble(code = rgva$geog_code,
#                             name = rgva$geog_name,
#                             type = rgva$geog_type)
#
# industry <- tibble::tibble(code = rgva$SIC07_code,
#                            name = rgva$SIC07_name,
#                            type = "SIC07")
#
# variable <- tibble::tibble(code = rgva$variable,
#                            name = dplyr::case_when(code == "cvm"       ~ "CVM Index",
#                                                    code == "constant"  ~ "Constant prices",
#                                                    code == "current"   ~ "Current prices",
#                                                    code == "deflators" ~ "Implied deflator",
#                                                    TRUE                ~ NA_character_),
#                            value = rgva$value)
#
# dates <- rgva$dates
#
# RGVA <- tibble::tibble(dates = dates,
#                        variable = variable,
#                        geography = geography,
#                        industry = industry)
#
# readr::write_rds(RGVA, "data/RGVA_new.rds")
