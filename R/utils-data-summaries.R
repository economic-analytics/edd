show_all_variables <- function() {
  lapply(edd_datasets, function(x) {
    tibble::tibble(code = x$dimension$variable$code,
                   variable = x$dimension$variable$name)
  }) |>
    dplyr::bind_rows(.id = "dataset")
}
