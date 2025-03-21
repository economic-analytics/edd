load_edd_dict <- function() {
  edd_dict <<- readr::read_csv("data/edd_dict.csv")
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