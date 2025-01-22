show_all_variables <- function() {
  all_dataset_ids <- edd_dict$id[!is.na(edd_dict$last_download)]

  all_variables <- lapply(
    all_dataset_ids,
    function(dataset_id) {
      retrieve_dataset(dataset_id)
    }
  )

  out <- do.call(arrow::concat_tables, all_variables)
  out <- out |>
    dplyr::distinct(dataset, variable.name)
  out <- dplyr::collect(out)

  return(out)
}
