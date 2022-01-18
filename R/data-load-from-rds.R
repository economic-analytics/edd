# fedo_dict    <- readr::read_csv("data-raw/fedo_dict.csv")
ons_datasets <- readr::read_rds("data/ons_datasets.rds")

variables    <- readr::read_rds("data/variables.rds")
boundaries   <- readr::read_rds("data/boundaries_nuts1-2-3.rds")
RGVA         <- readr::read_rds("data/ons_rgva_2019.rds")
RGVAI        <- readr::read_rds("data/ons_rgvai.rds")
BRES         <- readr::read_rds("data/bres.rds")
UKBC         <- readr::read_rds("data/ukbc.rds")

sp_datasets  <- list(RGVA  = RGVA,
                     RGVAI = RGVAI,
                     BRES  = BRES,
                     UKBC  = UKBC)

datasets <- list(ons_datasets = ons_datasets, sp_datasets = sp_datasets)

# this added to provide a second option - instead of two lists within a list
# we provide a single all_datasets list which contains ons and spatial
fedo_datasets <- c(ons_datasets, sp_datasets)
