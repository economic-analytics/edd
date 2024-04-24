load_edd_dict <- function() {
  edd_dict <<- readr::read_csv("data/edd_dict.csv")
}

update_edd_dict <- function(dataset_id, column, data) {
  edd_dict[[column]][edd_dict[["id"]] == dataset_id] <<- data
  readr::write_csv(edd_dict, "data/edd_dict.csv")
}

# Uses edd_dict as a global variable
load_edd_dict()