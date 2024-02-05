library(tidyverse)
library(readxl)
library(lubridate)

rti_nsa_url <- "https://www.ons.gov.uk/file?uri=%2femploymentandlabourmarket%2fpeopleinwork%2fearningsandworkinghours%2fdatasets%2frealtimeinformationstatisticsreferencetablenonseasonallyadjusted%2fcurrent/rtistatisticsreferencetablenotseasonallyadjusted.xlsx"

rti_nsa_path <- "data-raw/rti_nsa.xlsx"

download.file(rti_nsa_url, rti_nsa_path, method = "curl")

rti_sheets <- excel_sheets(rti_nsa_path)[-1] # Ignores Index (sheet 1)

rti <- lapply(rti_sheets, function(sht) read_excel(rti_nsa_path, sheet = sht, skip = 5))
names(rti) <- rti_sheets

rti_nsa_tidy <- lapply(rti, function(df) {
  df$Date <- my(df$Date)
  if (ncol(df) > 2) {
    pivot_longer(df, cols = -Date)
  } else {
    df
  }
})

write_rds(rti_nsa_tidy, "data/rti_nsa.rds")
