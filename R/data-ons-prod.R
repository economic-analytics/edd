
# ITL2/3 ------------------------------------------------------------------

ons_process_prod <- function() {
  prod_url <- "https://www.ons.gov.uk/file?uri=/employmentandlabourmarket/peopleinwork/labourproductivity/datasets/subregionalproductivitylabourproductivitygvaperhourworkedandgvaperfilledjobindicesbyuknuts2andnuts3subregions/current/itlproductivity.xlsx"

  prod_path <- "~/Data/ONS/Regional Accounts/Productivity/itlproductivity.xlsx"

  download.file(prod_url, prod_path, mode = "wb")

  prod <- readxl::read_excel(prod_path, "B3", skip = 3)
  names(prod)[1:3] <- c("geography_type", "geography_code", "geography_name")
  prod <- prod[-1, ]
  prod <- prod[complete.cases(prod), ]
  prod_data <- prod |>
    tidyr::pivot_longer(-(1:3), names_to = "date") |>
    dplyr::mutate(date_name = date,
                  date = as.Date(paste0(date, "-01-01")),
                  value = as.numeric(value),
                  variable_name = "GVA per filled job",
                  variable_unit = "£") |>
    dplyr::select(date, date_name,
                  geography_code, geography_name, geography_type,
                  variable_name, variable_unit,
                  value)

  # readr::write_csv(prod_data, "~/Data/ONS/Regional Accounts/Productivity/itlproductivity.csv")
}


# LAD ---------------------------------------------------------------------

# ons_process_prod_lad <- function() {
#   prod_lad_url <- "https://www.ons.gov.uk/file?uri=/employmentandlabourmarket/peopleinwork/labourproductivity/datasets/subregionalproductivitylabourproductivityindicesbylocalauthoritydistrict/current/ladproductivity.xlsx"

#   prod_lad_path <- "~/Data/ONS/Regional Accounts/Productivity"

#   prod_lad_file <- basename(prod_lad_url)

#   download.file(prod_lad_url, paste0(prod_lad_path, "/", prod_lad_file), mode = "wb")

#   prod_lad <- readxl::read_excel(paste0(prod_lad_path, "/", prod_lad_file), "B3", skip = 3)
#   names(prod_lad)[1:2] <- c("geography_code", "geography_name")
#   prod_lad <- prod_lad[-1, ]
#   prod_lad <- prod_lad[complete.cases(prod_lad), ]
#   prod_lad_data <- prod_lad |>
#     tidyr::pivot_longer(-(1:2), names_to = "date") |>
#     dplyr::mutate(date_name = date,
#                   date = as.Date(paste0(date, "-01-01")),
#                   value = as.numeric(value),
#                   variable_name = "GVA per filled job",
#                   variable_unit = "£",
#                   geography_type = "LAD") |>
#     dplyr::select(date, date_name,
#                   geography_code, geography_name, geography_type,
#                   variable_name, variable_unit,
#                   value)

  # readr::write_csv(prod_lad_data, file.path(prod_lad_path, "ladproductivity.csv"))
# }

# new stuff here

ons_process_prod_lad <- function() {
  url <- "https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/labourproductivity/datasets/subregionalproductivitylabourproductivityindicesbylocalauthoritydistrict"
  meta <- extract_ons_metadata(url)
  local_path <- "data-raw/prod_lad.xls"

  download.file(meta$files, local_path, mode = "wb")

  sheets <- c(
    index_hour = "A1",
    pounds_hour = "A3",
    index_job = "B1",
    pounds_job = "B3"
  )

  prod_lad <- lapply(sheets, function(sht) {
    x <- readxl::read_excel(local_path, sheet = sht, skip = 4)
    names(x) <- gsub("[A-Za-z]*\\_", "", names(x))
    return(x)
  }) |>
    dplyr::bind_rows(.id = "temp") |>
    tidyr::pivot_longer(
      tidyselect::where(is.numeric),
      names_to = "dates.date",
      values_drop_na = TRUE
    ) |>
    dplyr::mutate(
      dates.date = as.Date(paste0(dates.date, "-01-01")),
      dates.freq = "a") |>
    dplyr::mutate(variable.name = dplyr::case_when(
      temp == "index_hour" ~ "GVA per hour worked (UKX = 100)",
      temp == "pounds_hour" ~ "GVA per hour worked (£)",
      temp == "index_job" ~ "GVA per job (UKX = 100)",
      temp == "pounds_job" ~ "GVA per job (£)"
    )) |>
    dplyr::mutate(dataset = "PROD_LAD") |>
    dplyr::select(
      dataset,
      dates.date,
      dates.freq,
      geography.code = Code,
      geography.name = Name,
      variable.name,
      value
    )

  arrow::write_parquet(prod_lad, "data/parquet/PROD_LAD.parquet")
}

