rgva_lad <- function(path = NULL, url = NULL, force_update = FALSE) {

  if (is.null(path)) {
    path <- "data-raw/rgva_lad"
  }

  if (is.null(url)) {
    url <- "https://www.ons.gov.uk/economy/grossdomesticproductgdp/datasets/regionalgrossvalueaddedbalancedbyindustrylocalauthoritiesbyitl1region"
  }

  if (force_update) {
    urls <- rvest::read_html(url) |>
      rvest::html_elements("a") |>
      rvest::html_attr("href")

    files <- urls[grepl(".xlsx", urls)]
    file_urls <- paste0("http://ons.gov.uk", files) # http not https
  }

  all_data <- lapply(file_urls, function(file) {
    local_file_path <- paste0("data-raw/", basename(file))
    download.file(file, destfile = local_file_path, mode = "wb")
    sheets <- readxl::excel_sheets(local_file_path)
    sheets <- sheets[-(1:3)] # update
    data <- lapply(sheets, function(sht) {
      readxl::read_excel(local_file_path, sheet = sht, skip = 1, na = c("[c]"))
    })
    names(data) <- sheets
    return(data)
  })

  # number 13 is different (population). Tidy up all_data[1:12]
  final <- lapply(all_data[1:12], function(x) {
    lapply(x, function(sht) {
      dplyr::filter(sht, !is.na(`LA code`)) |>
        tidyr::pivot_longer(cols = -(1:5), names_to = "dates.date") |>
        dplyr::mutate(
          dates.date = as.Date(paste0(substr(dates.date, 1, 4), "-01-01"))
        )
    }) |>
      setNames(c("CVM Index", "GVA Constant Prices £m", "GVA Current Prices £m", "Implied deflator")) |>
      dplyr::bind_rows(.id = "variable.name")
  }) |>
    dplyr::bind_rows() |>
    dplyr::mutate(
      dates.freq = "a",
      dataset = "RGVA_LAD"
    ) |>
    dplyr::select(
      dataset,
      dates.date, dates.freq,
      variable.name,
      geography.code = `LA code`,
      geography.name = `LA name`,
      industry.code = SIC07,
      industry.name = `SIC07 description`,
      value
    )

  arrow::write_parquet(final, "data/parquet/RGVA_LAD.parquet")
}
