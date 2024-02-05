edd_datasets$UNEM |>
  edd_obj_to_dataframe() |> 
  arrow::write_parquet("workbench/unem.parquet")

unem <- arrow::read_parquet("workbench/unem.parquet",  as_data_frame = FALSE)

str(unem)

