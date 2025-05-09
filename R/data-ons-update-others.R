other_datasets_to_update <- function() {
  edd_dict |>
    dplyr::filter(
      status,
      !is.na(func),
      next_update <= Sys.Date() &
        next_update >= last_download
    )
}

update_other_datasets <- function() {
  for (dataset in other_datasets_to_update()$id) {
    process_function <- edd_dict$func[edd_dict$id == dataset]

    if (process_function == "ons_update_datasets") {
      # ons_update_datasets handles more than one base file
      # so its function needs the id as an argument
      do.call(process_function, list(dataset_id = dataset))
    } else {
      # other process_functions don't yet have the id argument
      do.call(process_function, list())
    }
  }
}
