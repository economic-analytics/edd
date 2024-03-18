ons_process_rgva <- function(filepath = NULL) {

  if (is.null(filepath)) {
    filepath <- "data-raw/regionalgrossvalueaddedbalancedbyindustryandallitlregions.xlsx"
  }

  # extract only those sheets with "Table" in the sheet name
  rgva_sheets <- readxl::excel_sheets(filepath)[
    grepl("Table", readxl::excel_sheets(filepath))
  ]

  rgva <- lapply(rgva_sheets, function(sht) {
    readxl::read_excel(
      path = filepath,
      sheet = sht,
      skip = 1,
      na = "u"
    )
  }) |>
    setNames(
      c(
        "ITL1_cvm", "ITL1_constant", "ITL1_current", "ITL1_deflators",
        "ITL2_cvm", "ITL2_constant", "ITL2_current", "ITL2_deflators",
        "ITL3_cvm", "ITL3_constant", "ITL3_current", "ITL3_deflators"
      )
    )
  # Set variable names of all dfs to that of the first
  rgva <- rgva |>
    lapply(function(df) setNames(df, names(rgva[[1]]))) |>
    # get rid of any footnote rows at the bottom of each table
    lapply(function(df) dplyr::filter(df, !is.na(`SIC07 code`))) |>
    # pivots dates to single column
    lapply(function(df) {
      tidyr::pivot_longer(
        df, cols = -(1:4), names_to = "dates"
      )
    }) |>
    dplyr::bind_rows(.id = "variable") |>
    tidyr::separate(
      col = "variable",
      into = c("geography.type", "variable.code"),
      sep = "_"
    ) |>
    dplyr::rename(
      geography.code = `ITL region code`,
      geography.name = `ITL region name`,
      industry.code = `SIC07 code`,
      industry.name = `SIC07 description`
    ) |>
    # removes any superscript notes at the end of dates
    dplyr::mutate(
      dates.date = as.Date(paste0(stringr::str_sub(dates, 1, 4), "-01-01")),
      dates.freq = "a",
      # if industry_code is single digit, add a leading zero
      industry.code = dplyr::case_when(
        grepl("[0-9]", industry.code) &
          stringr::str_length(industry.code) == 1 ~
          paste0("0", industry.code),
        TRUE ~ industry.code
      ),
      geography.type = dplyr::case_when(
        geography.code == "UK"  ~ "ctry",
        geography.code == "TLB" ~ "ctry",
        TRUE ~ geography.type
      ),
      variable.name = dplyr::case_when(
        variable.code == "cvm"       ~ "CVM Index",
        variable.code == "current"   ~ "Current prices",
        variable.code == "constant"  ~ "Constant prices",
        variable.code == "deflators" ~ "Implied deflator",
        TRUE ~ variable.code
      ),
      variable.unit = dplyr::case_when(
        variable.code == "cvm"       ~ "2019 = 100",
        variable.code == "constant"  ~ "2019 £m",
        variable.code == "current"   ~ "£m",
        variable.code == "deflators" ~ "2019 = 100",
        TRUE ~ variable.code
      ),
      dataset = "RGVA"
    ) |>
    dplyr::select(
      dataset,
      dates.date, dates.freq,
      geography.type, geography.code, geography.name,
      industry.code, industry.name,
      variable.code, variable.name, variable.unit,
      value
    )

  cat("Writing RGVA.parquet ...")
  arrow::write_parquet(rgva, "data/parquet/RGVA.parquet")
  cat("Done.")

  return(rgva)
}
