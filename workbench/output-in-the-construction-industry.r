cons <- readxl::read_excel("~/Data/bulletindataset2.xlsx", sheet = "Table 1a", skip = 4)

lookup <- data.frame(
  variable.name = names(cons)[-1],
  variable.code = cons[1, ][-1] |> as.character()
)

cons[-1, ] |>
  dplyr::rename(dates.date = `Time period`) |>
  dplyr::mutate(dates.freq = ifelse(
    nchar(dates.date) == 4, "a", ifelse(
      nchar(dates.date == 8), "m", "q")
    ),
    .after = "dates.date"
  ) |>
  View()



# extracting only the monthly data
first_row <- which(cons$`Time period` == "Jan 2010")
cons <- cons[-(1:(first_row - 1)), ]
cons <- cons |> 
  dplyr::select(-`All work`) |> 
  dplyr::mutate(`Time period` = as.Date(paste("01", `Time period`), format = "%d %b %Y")) |>
  tidyr::pivot_longer(-`Time period`, names_to = "Subsector") |> 
  dplyr::mutate(value = as.numeric(value)) |> 
  dplyr::filter(`Time period` >= "2020-01-01") |> 
  dplyr::filter(grepl("new", Subsector)) |> 
  dplyr::filter(!Subsector %in% c("Private new housing",
                                  "Public new housing",
                                  "All new work"))