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

  # determine which datasets from the dictionary to update
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

  for (i in seq_len(nrow(to_update))) {
    dataset_id <- to_update[[i, "id"]]
    message("Downloading ", dataset_id)
    file_location <- ons_download_dataset(to_update[[i, "url"]])

    message("Processing ", dataset_id)
    processed <- ons_process_dataset(file_location, dataset_id)

    message("Writing ", dataset_id)
    ons_write_dataset(processed, dataset_id)
  }

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
}

# Download data (not for export) ----

ons_download_dataset <- function(url) {
  destfile <- file.path("data-raw", basename(url))
  download_status <- download.file(url = url, destfile = destfile)

  if (download_status == 0) {
    message("Downloaded ", basename(url))
  }

  return(destfile)
}

ons_process_dataset <- function(csv, id) {
  # read, ignore column names, make everything strings
  dataset <- readr::read_csv(
    csv,
    col_names = FALSE,
    col_types = readr::cols(
      .default = readr::col_character()
    )
  )

  variable <- dataset[1:4, -1]
  variable <- tibble::tibble(
    variable.name = unname(unlist(variable[1, ])),
    variable.code = unname(unlist(variable[2, ])),
    variable.preunit = unname(unlist(variable[3, ])),
    variable.unit = unname(unlist(variable[4, ]))
  )

  meta <- dataset[5:7, -1]
  meta <- list(
    last_update = meta[[1, 1]],
    next_update = meta[[2, 1]],
    notes = meta[[3, 1]]
  )

  data <- dataset[-(1:7), ] |>
    setNames(c("dates", as.character(dataset[2, -1]))) |>
    dplyr::mutate(dates = date_text_to_df(dates)) |>
    tidyr::unnest(dates, names_sep = ".") |>
    tidyr::pivot_longer(
      cols = -dplyr::starts_with("dates"),
      names_to = "variable.code",
      values_drop_na = TRUE
    ) |>
    dplyr::mutate(value = as.numeric(value)) |>
    dplyr::left_join(variable, by = "variable.code") |>
    dplyr::mutate(dataset = id, .before = 1)

  eddobj <- list(
    data = data,
    meta = meta
  )

  class(eddobj) <- c(class(eddobj), "eddobj")

  return(eddobj)
}

ons_write_dataset <- function(eddobj, id) {

  arrow::write_parquet(
    eddobj$data,
    file.path(
      "data",
      "parquet",
      paste0(id, ".parquet")
    )
  )

  # Update edd_dict with metadata
  message("Updating edd_dict with metadata")
  print(eddobj$meta)

  update_edd_dict(
    id,
    "last_update",
    date_text_to_iso(eddobj$meta$last_update)
  )

  update_edd_dict(
    id,
    "next_update",
    date_text_to_iso(eddobj$meta$next_update)
  )

  update_edd_dict(
    id,
    "last_download",
    as.character(Sys.Date())
  )
}