ons_process_rgvai <- function(file_path = NULL,
                              save_processed_csv = TRUE,
                              df_to_edd = TRUE) {

  file_name <- "rgvai"
  file_ext <- "xlsx"

  if (is.null(file_path)) {
    rgvai_url <- "https://www.ons.gov.uk/file?uri=/economy/grossvalueaddedgva/datasets/nominalregionalgrossvalueaddedbalancedperheadandincomecomponents/current/regionalgrossvalueaddedbalancedperheadandincomecomponents.xlsx"
    rgvai_path <- file.path('data-raw', paste(file_name, file_ext, sep = "."))
    download.file(rgvai_url, rgvai_path, mode = "wb")
  } else {
    rgvai_path <- file_path
  }

  rgvai_sheets <- readxl::excel_sheets(rgvai_path)[
    grepl("Table", readxl::excel_sheets(rgvai_path))]

  rgvai <- lapply(rgvai_sheets, function(sht) {
    readxl::read_excel(rgvai_path, sheet = sht, skip = 1, na = "u")
  }) |>
    setNames(c("GVA (current prices £m)",
               "GVA per capita (current prices £)",
               "GVA per capita (index: UKX = 100)",
               "GVA (annual growth %)",
               "GVA per capita (annual growth %)",
               "GVA by industry (current prices £m)",
               "Compensation of employees (£m)",
               "Mixed income (£m)",
               "Rental income (£m)",
               "Non-market capital consumption (£m)",
               "Holding gains (£m)",
               "Gross trading profits (£m)",
               "Gross trading surplus (£m)",
               "Taxes on production (£m)",
               "Subsidies on production (£m)",
               "Statistical discrepancy (I vs B) (£m)",
               "Total resident population (ONS mid-year estimates)")
    )

  rgvai <- rgvai[-(1:5)] |>
    dplyr::bind_rows(.id = "variable") |>
    tidyr::pivot_longer(tidyselect::matches("^[0-9]{4}$"), names_to = "date") |>
    dplyr::select(date,
                  geography_code = `ITL code`,
                  geography_name = `Region name`,
                  geography_type = ITL,
                  industry_code = `SIC07 code`,
                  industry_name = `SIC07 industry`,
                  variable_name = variable,
                  variable_code = variable,
                  value) |>
    tidyr::replace_na(list(industry_code = "Total",
                           industry_name = "All industries"))

  if (save_processed_csv) {
    readr::write_csv(rgvai,
                     file.path("data-raw", "processed",
                               paste(file_name, "csv", sep = ".")
                     )
    )
  }

  if (df_to_edd) {
    saveRDS(df_to_edd_obj(rgvai),
            file.path("data", "datasets",
                      paste(toupper(file_name), "rds", sep = ".")
            )
    )
  }
}


