update_boe_yield_curves <- function() {

  latest_yield_curve_url <- "https://www.bankofengland.co.uk/-/media/boe/files/statistics/yield-curves/latest-yield-curve-data.zip"
  archive_yield_curve_url <- "https://www.bankofengland.co.uk/-/media/boe/files/statistics/yield-curves/oisddata.zip"

  td <- tempdir()

  download.file(
    latest_yield_curve_url,
    file.path(td, basename(latest_yield_curve_url))
  )

  download.file(
    archive_yield_curve_url,
    file.path(td, basename(archive_yield_curve_url))
  )

  unzip(
    zipfile = file.path(td, basename(latest_yield_curve_url)),
    exdir = file.path(
      "data-raw",
      basename(tools::file_path_sans_ext(latest_yield_curve_url))
    )
  )

  unzip(
    zipfile = file.path(td, basename(archive_yield_curve_url)),
    exdir = file.path(
      "data-raw",
      basename(tools::file_path_sans_ext(archive_yield_curve_url))
    )
  )

  boe_files <- c(
    # TODO: fix as this one has a different worksheet name
    # "data-raw/oisddata/OIS daily data_2009 to 2015.xlsx"
    "data-raw/oisddata/OIS daily data_2016 to 2024.xlsx",
    "data-raw/oisddata/OIS daily data_2025 to present.xlsx",
    "data-raw/latest-yield-curve-data/OIS daily data current month.xlsx"
  )

  ois <- lapply(boe_files, function(file) {
    readxl::read_excel(
      file,
      sheet = "1. fwds, short end",
      skip = 5,
      col_names = c("variable.name", 1:60)
    ) |>
      tidyr::pivot_longer(
        -variable.name,
        names_to = "months"
      ) |>
      dplyr::mutate(
        # variable.name = as.Date(variable.name, format = "%d %b %y"),
        months = as.integer(months)
      ) |>
      dplyr::mutate(
        months = as.Date(lubridate::`%m+%`(variable.name, months(months))),
        dates.freq = "d",
        dataset = "OIS",
        variable.code = months,
        variable.name = paste("Curve on", format(variable.name, "%d %B %Y"))
      ) |>
      dplyr::filter(!is.na(value)) |>
      dplyr::select(
        dataset,
        dates.date = months, dates.freq,
        variable.code, variable.name,
        value
      )
  }) |>
    dplyr::bind_rows()

  update_edd_dict_dates(
    "OIS",
    as.Date(max(ois$variable.code)),
    Sys.Date() + 1
  )

  arrow::write_parquet(ois, "data/parquet/OIS.parquet")
}