# dataFileLocation <- "data/parquet/"
dataFileLocation <- "https://economic-analytics.co.uk/edd-data/"

# edd_datasets <- arrow::open_dataset(dataFileLocation, unify_schemas = TRUE)
# the reading of parquet files will now take place in server.R based on the contents
# of input$dataset

# new function for retrieving parquet dataset
retrieve_dataset <- function(dataset_id) {
  arrow::read_parquet(
    paste0(
      dataFileLocation,
      dataset_id,
      ".parquet"
    ),
    as_data_frame = FALSE
  )
}