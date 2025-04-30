load_edd_dict <- function() {
  edd_dict <<- readr::read_csv(
    "https://data.economic-analytics.co.uk/edd/edd_dict.csv",
    col_types = readr::cols(
      type = readr::col_character(),
      provider = readr::col_character(),
      id = readr::col_character(),
      desc = readr::col_character(),
      page_url = readr::col_character(),
      url = readr::col_character(),
      func = readr::col_character(),
      last_update = readr::col_date(format = ""),
      next_update = readr::col_date(format = ""),
      last_download = readr::col_date(format = ""),
      status = readr::col_logical(),
      obj_available = readr::col_logical(),
      notes = readr::col_character()
    )
  )
}

update_edd_dict <- function(dataset_id, column, data) {
  edd_dict[[column]][edd_dict[["id"]] == dataset_id] <<- data
  readr::write_csv(edd_dict, "data/edd_dict.csv")
}

update_edd_dict_dates <- function(
  dataset_id,
  last_update,
  next_update,
  last_download = Sys.Date()
) {
  edd_dict$last_update[edd_dict$id == dataset_id] <<- last_update
  edd_dict$next_update[edd_dict$id == dataset_id] <<- next_update
  edd_dict$last_download[edd_dict$id == dataset_id] <<- last_download
  readr::write_csv(edd_dict, "data/edd_dict.csv")
}

# Uses edd_dict as a global variable
load_edd_dict()