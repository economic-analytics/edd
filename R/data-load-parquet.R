dataFileLocation <- "data/parquet"

edd_datasets <- arrow::open_dataset(dataFileLocation, unify_schemas = TRUE)
