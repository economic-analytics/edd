rgva_lad <- function() {
  rgva_la_url <- "https://www.ons.gov.uk/economy/grossdomesticproductgdp/datasets/regionalgrossvalueaddedbalancedbyindustrylocalauthoritiesbyitl1region"

  urls <- rvest::read_html(rgva_la_url) |>
    rvest::html_elements("a") |>
    rvest::html_attr("href")

  files <- urls[grepl(".xlsx", urls)]
  file_urls <- paste0("http://ons.gov.uk", files) # http not https

  all_data <- lapply(file_urls, function(file) {
    local_file_path <- paste0("data-raw/", basename(file))
    download.file(file, destfile = local_file_path, mode = "wb")
    sheets <- readxl::excel_sheets(local_file_path)
    sheets <- sheets[-(1:3)] # update
    data <- lapply(sheets, function(sht) {
      readxl::read_excel(local_file_path, sheet = sht, skip = 1, na = c("c"))
    })
    names(data) <- sheets
    return(data)
  })

  # number 13 is different (population). Tidy up all_data[1:12]
  final <- lapply(all_data[1:12], function(x) {
    lapply(x, function(sht) {
      dplyr::filter(sht, !is.na(`LAD code`)) |>
        tidyr::pivot_longer(cols = -(1:5), names_to = "date") |>
        dplyr::mutate(date = paste0(stringr::str_sub(date, 1, 4), "-01-01") |> as.Date())
    }) |>
      dplyr::bind_rows(.id = "variable")
  }) |> dplyr::bind_rows()

  #readr::write_rds(final, "data/rgva_lad.rds")
  #readr::write_csv(final, "../../Data/rgva_lad.csv")
}
