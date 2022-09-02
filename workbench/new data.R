# change old fedobj to new with separate and unified lookup objects
# must load package:fedo

data    <- lapply(fedo_datasets, function(ds) ds$data)
data_df <- lapply(fedo_datasets, function(ds) ds$data) %>% dplyr::bind_rows(.id = "dataset")

dimensions <- lapply(fedo_datasets, function(ds) ds$dimensions)

all_dimensions <- lapply(fedo_datasets, function(ds) names(ds$dimensions)) %>% unlist() %>% unique()

dimensions_variable  <- lapply(fedo_datasets, function(ds) ds$dimensions$variable)
dimensions_industry  <- lapply(fedo_datasets, function(ds) ds$dimensions$industry)
dimensions_geography <- lapply(fedo_datasets, function(ds) ds$dimensions$geography)
dimensions_employment_sizeband <- lapply(fedo_datasets, function(ds) ds$dimensions$employment_sizeband)
dimensions_legal_status <- lapply(fedo_datasets, function(ds) ds$dimensions$legal_status)

# rewrite above as single call

dimensions_list <- lapply(all_dimensions, function(dim) {
  lapply(fedo_datasets, function(ds) ds$dimensions[[dim]]) %>% dplyr::bind_rows(.id = "id")
  }
)

names(dimensions_list) <- all_dimensions

