# insolvencies

process_insolvencies  <- function(path = NULL) {

  if (is.null(path)) {
    path <- "~/Data/Insolvency/Data_Tables_in_Excel__xlsx__Format_-_Monthly_Insolvency_Statistics_February_2024.xlsx"
  }
  
  # aggregate ----

  INS1 <- readxl::read_excel(
    path,
    sheet = "Table 1",
    skip = 6,
    na = "[z]"
  ) |>
    dplyr::select(-Notes) |>
    dplyr::mutate(
      Month = as.Date(paste("01", Month), format = "%d %b %y"),
    ) |>
    dplyr::filter(!is.na(Month)) |>
    tidyr::pivot_longer(-Month, names_to = "variable.name") |>
    dplyr::mutate(
      dataset = "INS1",
      dates.freq = "m"
    ) |>
    dplyr::select(
      dataset,
      dates.date = Month,
      dates.freq,
      variable.name,
      value
    )

  arrow::write_parquet(INS1, "data/parquet/INS1.parquet")

  # by industry ---

  INS2 <- readxl::read_excel(
    path, sheet = "Table 2", skip = 7, na = c("[x]")
  ) |>
    dplyr::select(-Notes) |>
    dplyr::filter(Section != "Back to top") |>
    tidyr::pivot_longer(
      cols = -c(Section, Division, Description), names_to = "dates.date"
    ) |>
    dplyr::mutate(
      dates.date = as.Date(paste("01", dates.date), format = "%d %b %y"),
      dates.freq = "m"
    ) |>
    dplyr::mutate(
      Section = ifelse(!is.na(Division), NA, Section)
    ) |>
    tidyr::pivot_longer(
      cols = c(Section, Division),
      names_to = "industry.type",
      values_to = "industry.code",
      values_drop_na = TRUE
    ) |>
    dplyr::mutate(
      industry.type = ifelse(
        industry.code == "TOTAL", "SIC 2007", ifelse(
          industry.type == "Section", "SIC 2007 Section", ifelse(
            industry.type == "Division", "SIC 2007 Division", industry.type
          )
        )
      ),
      Description = ifelse(
        industry.code == "TOTAL", "All industries", Description
      )
    ) |>
    dplyr::mutate(
      dataset = "INS2",
      variable.name = "Number of insolvencies"
    ) |>
    dplyr::select(
      dataset,
      dates.date, dates.freq,
      industry.code, industry.name = Description, industry.type,
      variable.name,
      value
    )
  
  arrow::write_parquet(INS2, "data/parquet/INS2.parquet")
}