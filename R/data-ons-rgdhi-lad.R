ons_process_rgdhi_lad <- function(url = NULL, path = "data-raw") {

  if (is.null(url)) {
    url <- "https://www.ons.gov.uk/economy/regionalaccounts/grossdisposablehouseholdincome/datasets/regionalgrossdisposablehouseholdincomelocalauthoritiesbyitl1region"
  }

  meta <- extract_ons_metadata(url)

  local_files <- file.path(path, basename(meta$files))

  # download
  for (i in meta$files) {
    download.file(i, file.path(path, basename(i)), mode = "wb")
    Sys.sleep(2) # avoid rate limiting
  }

  # process
  all_data <- lapply(local_files, function(file) {
    sheets <- readxl::excel_sheets(file)
    sheets <- sheets[grepl("Table [7-8]", sheets)]
    data <- lapply(sheets, function(sht) {
      readxl::read_excel(
        file,
        sheet = sht,
        skip = 1,
        na = "u",
        .name_repair = tolower
      )
    }) |>
      setNames(
        c("GDHI total (£m) current prices",
          "GDHI per capita (£) current prices")
      ) |>
      dplyr::bind_rows(.id = "variable.name")

    return(data)
  }) |>
    dplyr::bind_rows() |>
    tidyr::pivot_longer(
      cols = dplyr::where(is.numeric),
      names_to = "dates.date"
    ) |>
    dplyr::mutate(
      dataset = "RGDHI",
      dates.date = as.Date(paste0(dates.date, "-01-01")),
      dates.freq = "a"
    ) |>
    dplyr::select(
      dataset,
      dates.date, dates.freq,
      variable.name,
      geography.code = `lad code`,
      geography.name = `region name`,
      transaction.code = `transaction code`,
      transaction.name = transaction,
      value
    )

  # write
  arrow::write_parquet(all_data, "data/parquet/RGDHI.parquet")

  # update metadata
  update_edd_dict("RGDHI", "last_update", meta$last_update)
  update_edd_dict("RGDHI", "next_update", meta$next_update)
  update_edd_dict("RGDHI", "last_download", Sys.Date())
}