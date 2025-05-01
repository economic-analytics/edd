# insolvencies

process_insolvencies  <- function(path = NULL) {

  # Collection
  # Company Insolvency Statistics Releases
  # https://www.gov.uk/government/collections/company-insolvency-statistics-releases

  url <- "https://www.gov.uk/government/collections/company-insolvency-statistics-releases"

  hrefs <- rvest::read_html(url) |>
    rvest::html_elements("a") |>
    rvest::html_attr("href")
  
  target <- hrefs[grepl("/government/statistics/company-insolvencies-", hrefs)][1]
  target <- paste0("https://www.gov.uk", target)

  links <- rvest::read_html(target) |>
    rvest::html_elements("a") |>
    rvest::html_attr("href")

  csv_url <- links[grepl("/Long-Run_Series_in_CSV_Format.*csv$", links)] |>
    unique()

  meta_url <- links[grepl("Metadata_for_Long-Run_Series_in_CSV_Format.*csv$", links)] |>
    unique()
  
  meta_temp <- readr::read_csv(meta_url, col_names = FALSE)
  blank_row <- which(is.na(meta_temp$X1))

  meta_temp <- readr::read_csv(meta_url, col_names = FALSE, n_max = blank_row - 1)

  meta <- list()

  for (i in seq_len(nrow(meta_temp))) {
    meta[[meta_temp$X1[i]]] <- meta_temp$X2[i]
  }

  meta_csv <- readr::read_csv(meta_url, skip = blank_row) |>
    dplyr::mutate(
      Description = ifelse(
        Is_Seasonally_Adjusted == "Y",
        paste(Description, "(SA)"),
        paste(Description, "(NSA)")
      )
    ) |>
    dplyr::select(
      variable.code = Variable,
      variable.name = Description,
      geography.name = Geography
    )

  INS1 <- readr::read_csv(
    csv_url,
    na = c(meta$`Not applicable`, meta$`Not available`)
  ) |>
    dplyr::select(-year, -month) |>
    dplyr::mutate(
      dates.date = as.Date(paste0(period, "-01")),
      dates.freq = "m",
      .before = 1,
    ) |>
    dplyr::select(-period) |>
    tidyr::pivot_longer(
      cols = -dplyr::starts_with("dates"),
      names_to = "variable.code",
      values_drop_na = TRUE
    ) |>
    dplyr::inner_join(meta_csv, by = "variable.code") |>
    dplyr::mutate(dataset = "INS1", .before = 1) |>
    dplyr::select(
      dataset,
      dates.date, dates.freq,
      variable.code, variable.name,
      geography.name,
      value
    )

  arrow::write_parquet(INS1, "data/parquet/INS1.parquet")

  # update edd_dict
  update_edd_dict(
    "INS1",
    "last_update",
    as.Date(meta$`Release date`, format = "%d/%m/%Y")
  )

  update_edd_dict(
    "INS1",
    "next_update",
    as.Date(meta$`Expiry date`, format = "%d/%m/%Y")
  )

  update_edd_dict(
    "INS1",
    "last_download",
    Sys.Date()
  )

  # by industry ---

  industry_url <- links[grepl("Industry_Tables_in_Excel__xlsx__Format", links)] |>
    unique()
  
  industry_path <- file.path("data-raw", basename(industry_url))

  download.file(
    industry_url,
    industry_path,
    mode = "wb"
  )

  INS2 <- readxl::read_excel(
    industry_path, sheet = "Table_A1a", skip = 5, na = c("[x]")
  ) |>
    dplyr::rename(
      industry.code = Section,
      industry.name = Description
    ) |>
    dplyr::mutate(
      industry.name = ifelse(
        industry.code == "TOTAL",
        "ALL INDUSTRIES",
        industry.name
      )
    ) |>
    tidyr::pivot_longer(
      cols = !dplyr::starts_with("industry"),
      names_to = "dates.date",
      values_drop_na = TRUE
    ) |>
    dplyr::mutate(
      dates.freq = ifelse(
        nchar(dates.date) == 4,
        "a",
        "m"
      ),
      dates.date = ifelse(
        nchar(dates.date) == 4,
        as.Date(paste0(dates.date, "-01-01")),
        as.Date(paste("01", dates.date), format = "%d %b %Y")
      ) |> as.Date()
    ) |>
    dplyr::mutate(
      industry.type = ifelse(
        industry.code == "TOTAL",
        "SIC 2007",
        "SIC 2007 Section"
      )
    ) |>
    dplyr::mutate(
      dataset = "INS2",
      variable.name = "Number of insolvencies (NSA)",
      geography.name = "England & Wales"
    ) |>
    dplyr::select(
      dataset,
      dates.date, dates.freq,
      variable.name,
      industry.code, industry.name, industry.type,
      geography.name,
      value
    )

  arrow::write_parquet(INS2, "data/parquet/INS2.parquet")

    # update edd_dict
  update_edd_dict(
    "INS2",
    "last_update",
    as.Date(meta$`Release date`, format = "%d/%m/%Y")
  )

  update_edd_dict(
    "INS2",
    "next_update",
    as.Date(meta$`Expiry date`, format = "%d/%m/%Y")
  )

  update_edd_dict(
    "INS2",
    "last_download",
    Sys.Date()
  )
}
