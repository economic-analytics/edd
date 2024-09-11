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
    eval(call(edd_dict$func[edd_dict$id == dataset]))
  }
}
