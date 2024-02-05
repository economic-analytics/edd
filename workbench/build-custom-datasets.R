# create housing affordability metrics

HPSSA2_knaresborough <- readRDS("~/Projects/Knaresborough Connectors/data/HPSSA2_knaresborough.rds")
saie_knaresborough <- readRDS("~/Projects/Knaresborough Connectors/data/saie_knaresborough.rds")

eddobj_to_df <- function(eddobj) {
  dims <- names(eddobj$dimensions)
  df <- eddobj$data
  for (dim in dims) {
    df <- merge(df, eddobj$dimensions[[dim]], by.x = dim, by.y = "code")
  }
  return(df)
}

eddobj_to_df(HPSSA2_knaresborough) |> View()
eddobj_to_df(saie_knaresborough) |> View()

x <- merge(eddobj_to_df(HPSSA2_knaresborough) |>
             dplyr::filter(house_type == "All house types") |>
             jsonlite::flatten(),
           eddobj_to_df(saie_knaresborough) |>
             dplyr::filter(variable == "Net annual income") |>
             jsonlite::flatten(),
           by = c(lubridate::year("dates.date"), "geography"))
