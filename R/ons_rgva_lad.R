rgva_lad <- function() {
  rgva_la_url <- "https://www.ons.gov.uk/economy/grossdomesticproductgdp/datasets/regionalgrossvalueaddedbalancedbyindustrylocalauthoritiesbyitl1region"
  urls <- rvest::read_html(rgva_la_url) %>%
    rvest::html_elements("a") %>%
    rvest::html_attr("href")
  files <- urls[grepl(".xlsx", urls)]
  file_urls <- paste0("http://ons.gov.uk", files)
  file_urls <- stringr::str_replace_all(file_urls, "%2f", "/")

  all_data <- lapply(1:13, function(file_no) {
    download.file(file_urls[file_no], destfile = paste0(file_no, ".xlsx"), mode = "wb")
    sheets <- readxl::excel_sheets(paste0(file_no, ".xlsx"))
    sheets <- sheets[-(1:2)]
    data <- lapply(sheets, function(sht) {
      readxl::read_excel(paste0(file_no, ".xlsx"), sheet = sht, skip = 1)
    })
    names(data) <- sheets
    return(data)
  })

  # number 13 is different - popn. Tidy up all_data[1:12]

  final <- lapply(all_data[1:12], function(x) {
    lapply(x, function(sht) {
      filter(sht, !is.na(`LAD code`)) %>%
        pivot_longer(cols = -(1:5), names_to = "date") %>%
        mutate(date = paste0(str_sub(date, 1, 4), "-01-01") %>% as.Date())
    }) %>%
      bind_rows(.id = "variable")
  }) %>% bind_rows()

  readr::write_rds(final, "data/rgva_lad.rds")
  readr::write_csv(final, "C:/Users/mail/OneDrive - MMU/Data/rgva_lad.csv")
}
