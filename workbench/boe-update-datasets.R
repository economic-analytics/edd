boe_update_datasets <- function() {
  boe <- readr::read_csv("http://www.bankofengland.co.uk/boeapps/iadb/fromshowcolumns.asp?csv.x=yes&Datefrom=01/Jan/2000&Dateto=Now&SeriesCodes=IUDBEDR,IUMAMNPY,IUMAAMIJ,XUDLUSS,XUDLERS,IUDSNIF,IUDMIIF,IUDLIIF,CFMZJ3U,CFMHSDC,IUMBV34,IUMB482,IUMBV37,IUMBV42&CSVF=TN&UsingCodes=Y&VPD=Y&VFD=N") |>
    dplyr::rename(`10-year Gilt` = IUMAMNPY,
                  `LIBOR` = IUMAAMIJ,
                  `Bank rate` = IUDBEDR,
                  `GBP:USD` = XUDLUSS,
                  `GBP:EUR` = XUDLERS,
                  `Implied forward yield 5-yr` = IUDSNIF,
                  `Implied forward yield 10-yr` = IUDMIIF,
                  `Implied forward yield 20-yr` = IUDLIIF,
                  `SME new fixed-rate loans` = CFMZJ3U,
                  `PNFC new fixed-rate loans` = CFMHSDC,
                  `2-year 75% LTV` = IUMBV34,
                  `2-year 90% LTV` = IUMB482,
                  `3-year 75% LTV` = IUMBV37,
                  `5-year 75% LTV` = IUMBV42) |>
    dplyr::mutate(DATE = as.Date(DATE, format = "%d %b %Y"))
}


boe_gilts <- function() {
  gilts <- readxl::read_excel("C:/Users/mail/Downloads/oisddata/OIS daily data_2016 to present.xlsx", sheet = "4. spot curve", skip = 3, col_types = c("date", rep("numeric", 50))) |>
    dplyr::select(`years:`, `2`, `5`, `10`, `20`, `25`) |>
    dplyr::filter(!is.na(`2`))
}

