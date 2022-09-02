# RGFCF eddie

# https://www.ons.gov.uk/economy/regionalaccounts/grossdisposablehouseholdincome/articles/experimentalregionalgrossfixedcapitalformationgfcfestimatesbyassettype1997to2020/2022-05-10

rgfcf_path <- "data-raw/experimentalregionalgfcf19972020byassetandindustry.xlsx"

rgfcf_url <- "https://www.ons.gov.uk/file?uri=%2feconomy%2fregionalaccounts%2fgrossdisposablehouseholdincome%2fdatasets%2fexperimentalregionalgrossfixedcapitalformationgfcfestimatesbyassettype%2f1997to2020/experimentalregionalgfcf19972020byassetandindustry.xlsx"

rgfcf_sheets <- readxl::excel_sheets(rgfcf_path)
rgfcf_data_sheets <- rgfcf_sheets[grepl("[0-9].[0-9]", rgfcf_sheets)]

rgfcf <- lapply(rgfcf_data_sheets, function(sht) {
  data <- readxl::read_excel(rgfcf_path,
                     sheet = sht,
                     skip = 3,
                     na = c("[w]", "[low]")) |>
    tidyr::pivot_longer(cols = `1997`:`2020`, names_to = "date") |>
    # dplyr::mutate(date = as.integer(date)) |>
    dplyr::filter(!is.na(Asset)) # Remove empty rows from data sheet 2
  # calculate the lowest ITL level in each df so we can remove the rest
  max_itl <- max(stringr::str_sub(names(data)[grepl("ITL[0-9]", names(data))], 4, 4))

  # select columns and rename to standards
  data |>
    dplyr::select(date, Asset,
                  dplyr::contains(paste0("ITL", max_itl)),
                  dplyr::contains("SIC07"), value) |>
    dplyr::rename(geography_name = 3, geography_code = 4,
                  industry_code = `SIC07 industry code`,
                  industry_name = `SIC07 industry name`,
                  variable_name = Asset,
    ) |>

    # add missing descriptors
    dplyr::mutate(geography_type = paste0("ITL", nchar(geography_code) - 2),
                  .before = geography_name) |>
    dplyr::mutate(variable_unit = "£m NSA Current Prices",
                  variable_code = variable_name) |>
    dplyr::mutate(industry_type = "SIC2007 Section") |>

    # final tidy - remove duplicates caused by TLZ
    dplyr::filter(!geography_code == "TLZ")
}) |>
  dplyr::bind_rows()


