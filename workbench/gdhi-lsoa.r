# gdhi-lsoa

url <- "https://www.ons.gov.uk/economy/regionalaccounts/grossdisposablehouseholdincome/datasets/englandsinternationalterritoriallevel1itl1regionsgranulargrossdisposablehouseholdincomeestimates2002to2021"

hrefs <- rvest::read_html(url) |>
  rvest::html_elements("a") |>
  rvest::html_attr("href")

england_hrefs <- paste0("https://www.ons.gov.uk", hrefs[grepl(".xlsx$", hrefs)])

# download all 9 excel files from England ITL1 regions

temp_location <- "data-raw/gdhi-lsoa"
dir.create(temp_location)

for (i in england_hrefs) {
  download.file(i, file.path(temp_location, basename(i)), mode= "wb")
}

files <- list.files(temp_location, full.names = TRUE)

gdhi.lsoa <- lapply(files, function(file) {
  x <- readxl::read_excel(file, sheet = "Table 1", skip = 1) |>
  tidyr::pivot_longer(
    dplyr::where(is.numeric),
    names_to = "dates.date"
  ) |>
  dplyr::mutate(
    dates.date = as.Date(paste0(dates.date, "-01-01")),
    dates.freq = "a",
    variable.unit = "£m, current prices",
    geography.type = "LSOA11"
  ) |>
  dplyr::select(
    dates.date, dates.freq,
    geography.code = `LSOA code`,
    geography.name = `LSOA name`,
    geography.type,
    variable.code = `Transaction code`,
    variable.name = `Transaction`,
    variable.unit,
    value
  )
}) |>
  dplyr::bind_rows()

out.file <- "data/parquet/GDHI-LSOA.parquet"
# arrow::write_parquet(gdhi.lsoa, "data/parquet/GDHI-LSOA.parquet")
