ons_process_rgvai <- function() {

  meta <- extract_ons_metadata(edd_dict$page_url[edd_dict$id == "RGVAI"])

  # download
  file_path <- file.path("data-raw", basename(meta$files))

  download.file(meta$files, file_path, mode = "wb")

  sheets <- readxl::excel_sheets(file_path)
  data_sheets <- sheets[grepl("Table", sheets)]

  lookup <- readxl::read_excel(file_path, sheet = "Contents", skip = 1) |>
    dplyr::mutate(`Table name` = gsub("Table [0-9]{1,2}: ", "", `Table name`)) |>
    dplyr::mutate(`Table name` = gsub(", pounds million", " £m", `Table name`)) |>
    dplyr::mutate(`Table name` = gsub(", percentage", " %", `Table name`)) |>
    dplyr::mutate(`Table name` = gsub("Gross value added \\(balanced\\)", "GVA", `Table name`)) |>
    dplyr::mutate(`Table name` = gsub("\\[.*\\]", "", `Table name`))

  rgvai <- lapply(data_sheets, function(sht) {
    readxl::read_excel(file_path, sheet = sht, skip = 1, na = "[u]")
  }) |>
    setNames(lookup$`Table name`)

  rgvai <- rgvai[-c(1:5, 17)] |>
    dplyr::bind_rows(.id = "variable.name") |>
    tidyr::pivot_longer(
      cols = tidyselect::matches("^[0-9]{4}$"),
      names_to = "dates.date",
      values_drop_na = TRUE
    ) |>
    dplyr::mutate(dataset = "RGVAI") |>
    dplyr::mutate(
      dates.date = as.Date(paste0(dates.date, "-01-01")),
      dates.freq = "a"
    ) |>
    dplyr::select(
      dataset,
      dates.date, dates.freq,
      geography.code = `ITL code`,
      geography.name = `Region name`,
      geography.type = ITL,
      industry.code = `SIC07 code`,
      industry.name = `SIC07 description`,
      variable.name,
      value
    ) |>
    tidyr::replace_na(
      list(
        industry.code = "Total",
        industry.name = "All industries"
      )
    )

  arrow::write_parquet(rgvai, "data/parquet/RGVAI.parquet")

  update_edd_dict("RGVAI", "last_update", meta$last_update)
  update_edd_dict("RGVAI", "next_update", meta$next_update)
  update_edd_dict("RGVAI", "last_download", Sys.Date())
}
