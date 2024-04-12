extract_ons_metadata <- function(ons_url) {
  ons_base_url = "https://www.ons.gov.uk"

  info = list()

  webpage = rvest::read_html(ons_url)

  info$url = ons_url

  info$meta = webpage |>
    rvest::html_nodes("li.meta__item") |>
    rvest::html_text2()
  
  info$last_update = info$meta[grepl("Release date", info$meta)] |>
    stringr::str_extract("[0-9]{1,2} [A-Za-z]* [0-9]{4}") |>
    as.Date(format = "%d %B %Y")

  info$next_update <- info$meta[grepl("Next release", info$meta)] |>
    stringr::str_extract("[0-9]{1,2} [A-Za-z]* [0-9]{4}") |>
    as.Date(format = "%d %B %Y")

  info$dataset_id <- if (any(stringr::str_detect(info$meta,"Dataset ID"))) {
    info$meta[grepl("Dataset ID", info$meta)] |>
    stringr::str_extract("[A-Z]{3,4}")
  } else {
    NA
  }
    
  info$title <- webpage |>
    rvest::html_nodes("h1.page-intro__title") |>
    rvest::html_text2() |>
    gsub("Dataset ", "", x = _)
  
  info$about <- webpage |>
    rvest::html_node(
      xpath = '//h2[contains(., "About this Dataset")]/parent::section/text()'
    ) |>
    rvest::html_text2()
  
  href <- webpage |>
    rvest::html_nodes("a.btn") |>
    rvest::html_attr("href")
  
  info$files <- paste0(
    ons_base_url,
    href[grepl("file\\?uri=", href)]
  )

  return(info)
}
