
rti_sa_url <- "https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/earningsandworkinghours/datasets/realtimeinformationstatisticsreferencetableseasonallyadjusted"

x <- rvest::read_html(rti_sa_url) |>
  rvest::html_elements("a") |>
  rvest::html_attr("href")
rti_sa_url <- paste0("http://www.ons.gov.uk", x[grepl(".xlsx", x)])

rti_sa_path <- "data-raw/rti_sa.xlsx"

download.file(rti_sa_url, rti_sa_path, mode = "wb")

# Ignores Index (sheet 1)
rti_sheets <- readxl::excel_sheets(rti_sa_path)[-1]

rti <- lapply(rti_sheets, function(sht) {
  temp <- readxl::read_excel(rti_sa_path, sheet = sht, col_names = FALSE)
  skip_rows <- which(grepl("Date", temp[[1]])) - 1

  # TODO problem with import - can't use that to filter the sheets
  import <- skip_rows[!is.na(skip_rows)]
  # ID empty tables
  final <- lapply(rti_sheets[import], function(x) {
    readxl::read_excel(rti_sa_path, sheet = x, skip = skip_rows)
  })
  names(final) <- rti_sheets[import]

  return(final)
  })

rti_sa_tidy <- lapply(rti, function(df) {
  df$Date <- lubridate::my(df$Date)
  if (ncol(df) > 2) {
    tidyr::pivot_longer(df, cols = -Date)
  } else {
    df
  }
})

saveRDS(rti_sa_tidy, "data/rti_sa.rds")
