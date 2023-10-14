ts_transform <- list()

ts_transform$nominal_change <- function(x) {
  x - lag(x)
}

ts_transform$percent_change <- function(x) {
  (x - lag(x)) / x * 100
}

ts_transform$cumulative_change <- function(x) {
  cumsum(c(0, diff(x)))
}

ts_transform$index <- function(x) {
  # x / x[1] * 100
  x / dplyr::first(x) * 100
}

ts_transform_df <- list()

ts_transform_df$nominal_change <- function(df) {
  df |>
    dplyr::mutate(value = value - dplyr::lag(value))
}

ts_transform_df$percent_change <- function(df) {
  df |>
    dplyr::mutate(value = (value - dplyr::lag(value)) / value * 100)
}

ts_transform_df$cumulative_change <- function(df) {
  df |>
    dplyr::mutate(value = cumsum(c(0, diff(value))))
}

ts_transform_df$index <- function(df, index_date = NULL) {
  df |>
    dplyr::mutate(value = value / value[dates$date == index_date] * 100)
}
