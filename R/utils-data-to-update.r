datasets_to_update <- function() {
  edd_dict |>
    dplyr::filter(
      next_update <= Sys.Date() & next_update >= last_download
    ) |>
    dplyr::select(id)
}
