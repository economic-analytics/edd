# This file contains all of the functions required to download all ONS datasets
# within the edd_dict and process them into the edd_obj format with data,
# variables and meta information in separate lists within lists for each
# time series object


# Master function (for export) --------------------------------------------

ons_update_datasets <- function(
  force_update = FALSE,
  save_separate_rds = TRUE,
  save_processed_csv = TRUE,
  save_parquet = TRUE,
  ...) {
  # problems with VROOM_CONNECTION_SIZE means we have to set this as the
  # download is large and overflows the connection buffer
  Sys.setenv("VROOM_CONNECTION_SIZE" = "500000")

  # conditions within edd_dict to update on
  to_update <- edd_dict |>
    dplyr::filter(type     == "dataset",
                  provider == "ONS",
                  status   == TRUE)
  
  # if updates aren't forced (default) then we'll only download those datasets
  # which should have had an update and haven't been downloaded since that date
  if (!force_update) {
    to_update <- to_update |>
      dplyr::filter(next_update <= Sys.Date() & next_update >= last_download)
  }
                  

  # TODO need to add condition for last_updated but need to implement the
  # writing back of the meta data to the edd_dict first

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
    edd_dict$last_update[edd_dict$id == names(processed)[i]] <- processed[[i]]$meta$last_update
    edd_dict$next_update[edd_dict$id == names(processed)[i]] <- processed[[i]]$meta$next_update
    edd_dict$last_download[edd_dict$id == names(processed)[i]] <- as.character(Sys.Date())
  }

  # rewrite edd_dict .rda and .csv
  save(edd_dict, file = 'data/edd_dict.rda')
  readr::write_csv(edd_dict, 'data-raw/edd_dict.csv')

  # # write separate .rds files for each dataset
  # if (save_separate_rds) {
  #   if (!dir.exists("data/datasets")) {
  #     dir.create("data/datasets")
  #   }
  #   for (i in seq_along(processed)) {
  #     message("Writing ", names(processed)[i], ".rds ...")
  #     saveRDS(processed[[i]],
  #             file.path("data", "datasets",
  #                       paste0(names(processed)[i], ".rds"))
  #     )
  #     message("Done.")
  #   }
  # }

  # write parquet files for each dataset
  if (save_parquet) {
    if (!dir.exists("data/parquet")) {
      dir.create("data/parquet")
    }

    for (i in seq_along(processed)) {
      message("Writing ", names(processed)[i], ".parquet ...")
      processed[[i]] |>
        edd_obj_to_dataframe() |> 
        tidyr::unnest(names_sep = ".") |>
        dplyr::mutate(dataset = basename(tools::file_path_sans_ext(names(processed)[i])), .before = 1) |>
        arrow::write_parquet(file.path("data", "parquet",
                              paste0(names(processed)[i], ".parquet")))
    }
  }

  # if (save_processed_csv) {
  #   if (!dir.exists("data/csv")) {
  #     dir.create("data/csv")
  #   }
  #   for (i in seq_along(processed)) {
  #     message("Writing ", names(processed)[i], ".csv files ...")
  #     readr::write_csv(jsonlite::flatten(processed[[i]]$data),
  #                      file.path("data", "csv",
  #                                paste0(names(processed)[i], "_data.csv"))
  #     )

  #     for (j in seq_along(processed[[i]]$dimensions)) {
  #       readr::write_csv(jsonlite::flatten(processed[[i]][["dimensions"]][[j]]),
  #                        file.path("data", "csv",
  #                                  paste0(names(processed)[i],
  #                                         "_",
  #                                         names(processed[[i]][["dimensions"]])[j], "_lookup.csv")))
  #     }
  #   }
  # }
}


# Download data (not for export) ------------------------------------------

ons_download_dataset <- function(url, save_csv = TRUE) {

  # if we want to keep a copy of the original ONS .csv
  if (save_csv) {
    if (!dir.exists("data-raw")) {
      dir.create("data-raw")
    }

    destfile = file.path("data-raw/", basename(url))
    download.file(url = url, destfile = destfile)

    # update value of url so that if we've saved a csv,
    # we read from the file path not the url, otherwise
    # we just read from url as there's no local copy
    url <- destfile
  }

  # read, ignore column names, make everything strings
  dataset <- readr::read_csv(url,
                             col_names = FALSE,
                             col_types = readr::cols(
                               .default = readr::col_character()
                             )
  )
  return(dataset)
}


# Process raw df (not for export) -----------------------------------------

# this function parses the downloaded csv files and puts them into an edd_obj
ons_process_dataset <- function(dataset, new_format = FALSE) {
  if (new_format) {
    variable <- dataset[1:4, ]
    variable <- tibble::as_tibble(variable)
    variable <- t(variable)
    variable <- tibble::as_tibble(variable)
    names(variable) <- as.character(variable[1, ])
    names(variable) <- c("name", "code", "preunit", "unit")
    variable <- variable[-1, ]

    meta <- dataset[5:7, ]
    meta <- tibble::as_tibble(meta)
    meta <- t(meta)
    meta <- tibble::as_tibble(meta)
    names(meta) <- as.character(meta[1, ])
    meta <- meta[-1, ]
    meta <- dplyr::distinct(na.omit(meta))

    names(dataset) <- c("date", as.character(dataset[2, -1]))
    dataset <- dataset[-(1:7), ]
    dataset$date <- date_text_to_df(dataset$date)
    dataset <- tidyr::pivot_longer(dataset, cols = -date, names_to = "variable")
    dataset$value <- as.numeric(dataset$value)

    x <- dplyr::left_join(dataset, variable, by = c("variable" = "code"))
    var_df <- x %>%
      dplyr::select(-date) %>%
      dplyr::rename(code = variable)

    dataset <- tibble::tibble(dates = dataset$date,
                              variable = var_df)

    dataset <- dplyr::filter(dataset, !is.na(variable$value))

    return(dataset)
  } else {
    # separate variable and meta parts of dataset
    variable <- dataset[1:4, ]
    meta  <- dataset[5:7, ]

    #rename data variable and drop variable and meta rows
    names(dataset) <- c("dates", dataset[2, -1])
    data  <- dataset[-(1:7), ]

    # prepare data
    data$dates <- date_text_to_df(data$dates)
    data <- tidyr::pivot_longer(data, -dates, names_to = "variable", values_to = "value", values_drop_na = TRUE)
    data$value <- as.numeric(data$value)
    data <- dplyr::filter(data, !is.na(value))

    # prepare meta
    meta <- t(meta)
    meta <- tibble::as_tibble(meta)
    names(meta) <- meta[1, ]
    meta <- dplyr::rename(meta,
                          last_update = `Release Date`,
                          next_update = `Next release`,
                          notes       = `Important Notes`
    )
    meta <- meta[-1, ]
    meta <- unique(meta)

    last_update <- date_text_to_iso(unique(meta$last_update))
    next_update <- date_text_to_iso(unique(meta$next_update))
    notes <- unique(na.omit(meta$notes))

    meta <- list(last_update = last_update,
                 next_update = next_update,
                 notes = notes)

    # prepare variable df
    variable <- t(variable)
    variable <- tibble::as_tibble(variable)
    names(variable) <- tolower(variable[1, ])
    variable <- variable[-1, ]
    variable <- dplyr::select(variable,
                              code = cdid,
                              name = title,
                              unit,
                              preunit)

    # removing from code as the data df doesn't contain a geography column
    # geography <- tibble::tibble(code = "UK", name = "UK")
    dimensions <- list(variable  = variable) #,
    # geography = geography)

    # prepare final object
    processed <- list(data = data,
                      dimensions = dimensions,
                      meta = meta)

    # readr::write_rds(ons_datasets, "../../Data/ONS/ons_datasets.rds")

    return(processed)
  }
}
