
latest_yield_curve_url <- "https://www.bankofengland.co.uk/-/media/boe/files/statistics/yield-curves/latest-yield-curve-data.zip"
archive_yield_curve_url <- "https://www.bankofengland.co.uk/-/media/boe/files/statistics/yield-curves/oisddata.zip"

# TODO these can be redirected to edd/data-raw when integrated
# as all other dependencies on this data can then read from edd
latest_yield_curve_path <- "~/Data/Bank of England/"
archive_yield_curve_path <- "~/Data/Bank of England/"

download.file(latest_yield_curve_url, file.path(latest_yield_curve_path, basename(latest_yield_curve_url)))
download.file(archive_yield_curve_url, file.path(archive_yield_curve_path, basename(archive_yield_curve_url)))

unzip(file.path(latest_yield_curve_path, basename(latest_yield_curve_url)), exdir = file.path(latest_yield_curve_path, basename(tools::file_path_sans_ext(latest_yield_curve_url))))
unzip(file.path(archive_yield_curve_path, basename(archive_yield_curve_url)), exdir = file.path(archive_yield_curve_path, basename(tools::file_path_sans_ext(archive_yield_curve_url))))

# list.files(file.path(latest_yield_curve_path, basename(tools::file_path_sans_ext(latest_yield_curve_url))))
# list.files(file.path(archive_yield_curve_path, basename(tools::file_path_sans_ext(archive_yield_curve_url))))

# readxl::excel_sheets(list.files(file.path(archive_yield_curve_path, basename(tools::file_path_sans_ext(archive_yield_curve_url))), full.names = TRUE)[3])

boe_files <- c(
  # "~/Data/Bank of England/oisddata/OIS daily data_2009 to 2015.xlsx", # different worksheet name
  "~/Data/Bank of England/oisddata/OIS daily data_2016 to 2024.xlsx",
  "~/Data/Bank of England/oisddata/OIS daily data_2025 to present.xlsx",
  "~/Data/Bank of England/latest-yield-curve-data/OIS daily data current month.xlsx"
)

x <- lapply(boe_files, function(file) {
  readxl::read_excel(
    file, sheet = "1. fwds, short end",
    skip = 5,
    col_names = c("date", 1:60)
  ) |>
  tidyr::pivot_longer(-date, names_to = "months") |>
  dplyr::mutate(
    date = as.Date(date, format = "%d %b %y"),
    months = as.integer(months)
  ) |>
  # dplyr::mutate(months = date + lubridate::dmonths(months)) |>
  dplyr::mutate(months = lubridate::`%m+%`(date, months(months))) |>
  dplyr::filter(!is.na(value))
}) |>
  dplyr::bind_rows()
  

# x <- readxl::read_excel(list.files(file.path(archive_yield_curve_path, basename(tools::file_path_sans_ext(archive_yield_curve_url))), full.names = TRUE)[3], sheet = "1. fwds, short end",
# skip = 4, col_names = c("date", 1:60)) |>
#   dplyr::bind_rows(
#     readxl::read_excel(list.files(file.path(latest_yield_curve_path, basename(tools::file_path_sans_ext(latest_yield_curve_url))), full.names = TRUE)[4], sheet = "1. fwds, short end",
# skip = 4, col_names = c("date", 1:60))
#   ) |>
#   tidyr::pivot_longer(-date, names_to = "months") |>
#   dplyr::mutate(months = date + lubridate::dmonths(as.integer(months))) |>
#   dplyr::mutate(date = as.Date(date), months = as.Date(months)) |>
#   dplyr::filter(!is.na(value))


x |>
  dplyr::filter(date >= "2024-07-01") |>
  ggplot2::ggplot(ggplot2::aes(x = months, y = value, colour = lubridate::month(date, label = TRUE), alpha = lubridate::day(date), group = date)) +
  ggplot2::geom_line() +
  ggplot2::scale_colour_brewer(type = "qual", palette = "Set3") +
  ggplot2::theme(legend.position = "top") +
  ggplot2::ylim(3, 5.5) +
  ggplot2::xlim(as.Date("2024-01-01"), NA) +
  ggplot2::labs(
    title = "Overnight index swap rates",
    subtitle = "Markets have been rapidly changing their assessments of future Bank Rate",
    x = NULL,
    y = "%",
    colour = "Month",
    alpha = "Day"
  ) +
  ggplot2::scale_x_date(date_breaks = "year", date_labels = "%Y")

RColorBrewer::display.brewer.all()

## BoE market-implied rate cuts

```{r boe-path-simple}
current_rate = 4.5
x |>
  dplyr::filter(date == max(date) | date == as.Date("2024-10-29")) |>
  dplyr::mutate(cuts = -floor((current_rate - value) / 0.25)) |>
  ggplot2::ggplot(ggplot2::aes(x = months, y = cuts, colour = as.factor(date))) +
  ggplot2::geom_line(linewidth = 1) +
  chart_theme +
  ggplot2::labs(
    title = "Market implied number of cuts to Bank Rate",
    subtitle = "From instantaneous forward OIS curve",
    x = NULL,
    y = "Number of BoE cuts",
    colour = "Date"
  ) +
  ggplot2::scale_x_date(date_breaks = "year", date_labels = "%Y")
```