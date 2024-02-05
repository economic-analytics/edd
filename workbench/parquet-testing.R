edd_datasets$UNEM |>
  edd_obj_to_dataframe() |> 
  tidyr::unnest() |>
  arrow::write_parquet("workbench/unem.parquet")

unem <- arrow::read_parquet("workbench/unem.parquet",  as_data_frame = FALSE)

str(unem)

unem <- arrow::read_parquet(
  "https://github.com/economic-analytics/edd/raw/main/workbench/unem.parquet",
  as_data_frame = FALSE
)

unem$variable