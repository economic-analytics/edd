update_edd_dict <- function(dataset_id, column, data) {
  edd_dict[[column]][edd_dict$id == dataset_id]  <<- data
  readr::write_csv(edd_dict, "data/edd_dict.csv")
}
