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

arrow::read_parquet("workbench/parquet/mm23.parquet")
pd |>
dplyr::distinct(variable.name) |> dplyr::collect()


# testing against edd repo parquet files

# fails with unrecognized filesystem type
all <- arrow::open_dataset("https://github.com/economic-analytics/edd/raw/main/data/parquet")

# runs ok on local file system
all_local <- arrow::open_dataset("data/parquet")
all_local # doesn't pick up different schema from RGVA

all_local <- arrow::open_dataset("data/parquet", unify_schemas = T)
all_local # this gets the RGVA fields

# very fast! :-)
all_local |> dplyr::distinct(variable.name) |> dplyr::collect()

# not all files have the same schema. Some have geog, ind, etc.
rgva <- arrow::read_parquet("data/parquet/RGVA.parquet", as_data_frame = F)
rgva
rgva$metadata
rgva |> dplyr::distinct(geography)

# need to call unify_schemas = TRUE
two_schemas <- arrow::open_dataset(c("data/parquet/UNEM.parquet", "data/parquet/RGVA.parquet"), unify_schemas = T)

two_schemas

two_schemas |> 
  #dplyr::distinct(geography) |> 
  dplyr::collect() |> View()

