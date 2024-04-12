# This file contains all of the functions required to download all ONS datasets
# within the edd_dict and process them into the edd_obj format with data,
# variables and meta information in separate lists within lists for each
# time series object

# Master function (for export) ----

ons_update_datasets <- function(
  force_update = FALSE,
  save_parquet = TRUE,
  ...
) {
  # problems with VROOM_CONNECTION_SIZE means we have to set this as the
  # download is large and overflows the connection buffer
  Sys.setenv("VROOM_CONNECTION_SIZE" = "500000")

  # conditions within edd_dict to update on
  to_update <- edd_dict |>
    dplyr::filter(
      type     == "dataset",
      provider == "ONS",
      status   == TRUE
    )

  # if updates aren't forced (default) then we'll only download those datasets
  # which should have had an update and haven't been downloaded since that date
  if (!force_update) {
    to_update <- to_update |>
      dplyr::filter(next_update <= Sys.Date() & next_update >= last_download)
  }

  datasets <- lapply(to_update$url,
                     function(url) {
                       ons_download_dataset(url, ...)
                     })
  names(datasets) <- to_update$id

  processed <- lapply(datasets, function(x) ons_process_dataset(x))

  # # ONS POST PROCESSING - STILL TESTING
  # processed <- lapply(seq_along(processed), function(i, ds_name) {
  #   if (ds_name[[i]] %in% names(ons_post_processing)) {
  #     ppobj <- ons_post_processing[[ds_name[[i]]]](processed[[i]])
  #   } else {
  #     processed[[i]]
  #   }
  # },
  # ds_name = names(processed)
  # ) %>% setNames(names(processed))

  # Update edd_dict with metadata
  message("Updating edd_dict with metadata")

  for (i in seq_along(processed)) {
    update_edd_dict(
      names(processed)[i],
      "last_update",
      processed[[i]]$meta$last_update
    )
    update_edd_dict(
      names(processed)[i],
      "next_update",
      processed[[i]]$meta$next_update
    )
    update_edd_dict(
      names(processed)[i],
      "last_download",
      as.character(Sys.Date())
    )
  }

  # write parquet files for each dataset
  if (save_parquet) {
    if (!dir.exists("data/parquet")) {
      dir.create("data/parquet")
    }

    for (i in seq_along(processed)) {
      message("Writing ", names(processed)[i], ".parquet ...")
      processed[[i]] |>
        dplyr::mutate(dataset = names(processed)[i], .before = 1) |>
        arrow::write_parquet(
          file.path(
            "data",
            "parquet",
            paste0(names(processed)[i], ".parquet")
          )
        )
    }
  }
}

# Download data (not for export) ----

ons_download_dataset <- function(url, save_csv = TRUE) {

  # if we want to keep a copy of the original ONS .csv
  if (save_csv) {
    if (!dir.exists("data-raw")) {
      dir.create("data-raw")
    }

    destfile <- file.path("data-raw/", basename(url))
    download.file(url = url, destfile = destfile)

    # update value of url so that if we've saved a csv,
    # we read from the file path not the url, otherwise
    # we just read from url as there's no local copy
    url <- destfile
  }

  # read, ignore column names, make everything strings
  dataset <- readr::read_csv(
    url,
    col_names = FALSE,
    col_types = readr::cols(
      .default = readr::col_character()
    )
  )

  return(dataset)
}


# Process raw df (not for export) ----

# this function parses the downloaded csv files
ons_process_dataset <- function(dataset) {
  variable <- dataset[1:4, -1] |>
    t() |>
    tibble::as_tibble() |>
    setNames(c(
      "variable.name",
      "variable.code",
      "variable.preunit",
      "variable.unit"
    ))

  meta <- dataset[5:7, -1] |>
    t() |>
    tibble::as_tibble() |>
    dplyr::distinct() |>
    setNames(c(
      "last_update",
      "next_update",
      "notes"
    )) |>
    as.list() # we may need an na.omit() here

  names(dataset) <- c("dates", as.character(dataset[2, -1]))
  dataset <- dataset[-(1:7), ]
  dataset <- dataset |>
    dplyr::mutate(dates = date_text_to_df(dates)) |>
    tidyr::unnest(dates, names_sep = ".") |>
    tidyr::pivot_longer(
      cols = -dplyr::starts_with("dates"),
      names_to = "variable.code",
      values_drop_na = TRUE
    ) |>
    dplyr::mutate(value = as.numeric(value)) |>
    dplyr::left_join(variable)

  return(dataset)
}
