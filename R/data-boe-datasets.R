# boe

update_boe_datasets <- function() {
  boe_codes <- "IUDBEDR,IUMAMNPY,IUMAAMIJ,XUDLUSS,XUDLERS,IUDSNIF,IUDMIIF,IUDLIIF,CFMZJ3U,CFMHSDC,IUMBV34,IUMB482,IUMBV37,IUMBV42,LPMVTVX,LPMB4B3,RPMZKU4,RPMZKU5,RPMZ8YH,RPMZ8YI"

  url <- paste0(
    "http://www.bankofengland.co.uk/boeapps/iadb/fromshowcolumns.asp?csv.x=yes&Datefrom=01/Jan/2000&Dateto=Now&SeriesCodes=",
    boe_codes,
    "&CSVF=CT&UsingCodes=Y&VPD=Y&VFD=N"
  )

  tempfile <- tempfile(fileext = ".csv")
  download.file(url, tempfile)
  temp <- readr::read_csv(tempfile)
  first_row <- which(temp$SERIES == "DATE")
  lookup <- temp[1:first_row - 1, ]
  boe <- tibble::tibble(
    temp[-(1:first_row), 1],
    temp[-(1:first_row), 2]
  ) |>
    dplyr::mutate(
      dates.date = as.Date(SERIES, format = "%d %b %Y"),
      # TODO dates.freq should be determined on a series-by-series basis
      dates.freq = "d"
    ) |>
    dplyr::mutate(dataset = "BOE") |>
    tidyr::separate(DESCRIPTION, into = c("variable.code", "value"), ",") |>
    dplyr::inner_join(lookup, by = c("variable.code" = "SERIES")) |>
    dplyr::select(
      dataset,
      dates.date, dates.freq,
      variable.code, variable.name = DESCRIPTION,
      value
    ) |>
    dplyr::mutate(value = as.numeric(value))

  update_edd_dict(
    "BOE",
    "last_update",
    max(boe$dates.date, na.rm = TRUE)
  )

  update_edd_dict(
    "BOE",
    "next_update",
    # TODO needs to set next_update to next working day from today
    Sys.Date() + 1
  )

  update_edd_dict(
    "BOE",
    "last_download",
    Sys.Date()
  )

  arrow::write_parquet(boe, "data/parquet/BOE.parquet")
}
