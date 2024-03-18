show_all_variables <- function() {
  edd_datasets |>
    dplyr::distinct(dataset, variable.code, variable.name) |>
    dplyr::collect()
}
