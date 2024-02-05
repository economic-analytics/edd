dir.create("workbench/parquet")

edd_datasets$UNEM |>
  edd_obj_to_dataframe() |> 
  tidyr::unnest(names_sep = ".") |>
  arrow::write_parquet("workbench/parquet/unem.parquet")

edd_datasets$MM23 |>
  edd_obj_to_dataframe() |> 
  tidyr::unnest(names_sep = ".") |>
  arrow::write_parquet("workbench/parquet/mm23.parquet")

edd_datasets$UNEM |>
  edd_obj_to_dataframe() |> 
  tidyr::unnest(names_sep = ".") |>
  readr::write_csv("workbench/unem.csv")


unem <- arrow::read_parquet("workbench/unem.parquet",  as_data_frame = T)

str(unem)

unem <- arrow::read_parquet(
  "https://github.com/economic-analytics/edd/raw/main/workbench/unem.parquet",
  as_data_frame = FALSE
)

mm23 <- arrow::read_parquet(
  "https://github.com/economic-analytics/edd/raw/main/workbench/mm23.parquet",
  as_data_frame = FALSE
)

u |>nem$variable.name |> dplyr::collect()


unem |>
  dplyr::distinct(variable.name) |>
  dplyr::collect()

unem |> dplyr::collect()

mm23  |>
  dplyr::collect()

d <- c("unem", "mm23")

lapply(seq_along(d), function(x) {
  get(d[x]) |>
  dplyr::collect()
  }) |> 
  setNames(d) |>
  dplyr::bind_rows(.id = "dataset")

pd <- arrow::open_dataset("workbench/parquet")
arrow::open_dataset()
pd$variable.name

pd |>
dplyr::distinct(variable.name) |> dplyr::collect()
