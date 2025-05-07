# RGFCF

ons_process_rgfcf <- function() {

  meta <- extract_ons_metadata(edd_dict$page_url[edd_dict$id == "RGFCF"])

  rgfcf_path <- file.path("data-raw", basename(meta$files[1]))

  download.file(
    meta$files[1],
    rgfcf_path,
    mode = "wb"
  )

  # published data can be considered in four individual formats
  # 1.1-1.4: dwelling investment (total) by ITL1, 2, 3, LAD
  # 1.1a-1.4a dwelling investment (by asset type) by ITL1, 2, 3, LAD
  # 2.1-2.4: other buildings and structures investment (total) by ITL1, 2, 3, LAD
  # 2.1a-2.4a: other buildings and structures investment (by asset type) by ITL1, 2, 3, LAD

  # We'll combine 1.1-1.4 for all geographies, adding a geography_type and an asset_type (total)
  # Then add 1.1a-1.4a to this, using asset_type as asset_code, and then join to sheet 3 for the lookup to asset_name
  # Repeat for 2.1-2.4 and 2.1a-2.4a

  rgfcf_sheets <- readxl::excel_sheets(rgfcf_path)
  rgfcf_data_sheets <- rgfcf_sheets[grepl("[0-9].[0-9]", rgfcf_sheets)]

  rgfcf <- lapply(rgfcf_data_sheets, function(sht) {
    data <- readxl::read_excel(
      rgfcf_path,
      sheet = sht,
      skip = 3,
      na = c("z")
    )

    years <- names(data)[grepl("[0-9]{4}", names(data))]
    geog <- if (substr(names(data)[1], 1, 3) == "ITL") {
      substr(names(data)[1], 1, 4)
    } else {
      "LAD"
    }

    data <- data |>
      tidyr::pivot_longer(
        cols = dplyr::all_of(years),
        names_to = "dates.date",
        values_drop_na = TRUE
      ) |>
      dplyr::mutate(value = as.numeric(value)) |>
      dplyr::mutate(dates.date = as.Date(paste0(dates.date, "-01-01"))) |>
      dplyr::mutate(dates.freq = "a") |>
      dplyr::rename(
        geography.code = 1,
        geography.name = 2
      ) |>
      dplyr::mutate(asset.type = ifelse(
        substr(sht, 6, 6) == "1",
        "Dwellings",
        "Other buildings and structures"
      )) |>
      dplyr::mutate(
        geography.type = geog,
        variable.name = "GFCF £m NSA Current Prices"
      )
  }) |>
    setNames(rgfcf_data_sheets) |>
    dplyr::bind_rows() |>
    dplyr::left_join(
      readxl::read_excel(
        rgfcf_path,
        sheet = "Asset and data sources",
        col_types = c("skip", "text", "text", "skip"),
      ),
      by = c("asset_detail" = "Shortened asset detail name")
    ) |>
    tidyr::replace_na(list(
      asset_detail = "total",
      `Full asset detail name` = "Total"
    )) |>
    dplyr::mutate(dataset = "RGFCF") |>
    dplyr::select(
      dataset,
      dates.date, dates.freq,
      geography.code, geography.name, geography.type,
      asset_type.name = asset.type,
      asset_detail.code = asset_detail,
      asset_detail.name = `Full asset detail name`,
      variable.name,
      value
    )

  arrow::write_parquet(rgfcf, "data/parquet/RGFCF.parquet")

  # update meta data

  update_edd_dict("RGFCF", "last_update", meta$last_update)
  update_edd_dict("RGFCF", "next_update", meta$next_update)
  update_edd_dict("RGFCF", "last_download", Sys.Date())
}