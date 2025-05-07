process_rgva_lad <- function() {

  meta <- extract_ons_metadata(edd_dict$page_url[edd_dict$id == "RGVA_LAD"])

  # download files
  local_files <- vector(mode = "character")
  for (file in meta$files) {
    local_file_path <- paste0("data-raw/", basename(file))
    download.file(file, destfile = local_file_path, mode = "wb")
    local_files[file] <- local_file_path
    Sys.sleep(2)
  }

  all_data <- lapply(local_files, function(file) {
    sheets <- readxl::excel_sheets(file)
    sheets <- sheets[-(1:3)] # update
    data <- lapply(sheets, function(sht) {
      readxl::read_excel(file, sheet = sht, skip = 1, na = c("[c]", "[u]"))
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

  update_edd_dict_dates("RGVA_LAD", meta$last_update, meta$next_update)
}
