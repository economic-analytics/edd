# fedo_dict    <- readr::read_csv("data-raw/fedo_dict.csv")

#ons_datasets <- readr::read_rds("data/ons_datasets.rds")

#variables    <- readr::read_rds("data/variables.rds")
#boundaries   <- readr::read_rds("data/boundaries_nuts1-2-3.rds")
RGVA         <- readr::read_rds("data/rgva_msoa.rds")
#RGVAI        <- readr::read_rds("data/ons_rgvai.rds")
BRES         <- readr::read_rds("data/bres_msoa.rds")
UKBC         <- readr::read_rds("data/ukbc_knaresborough.rds")
#RGFCF        <- readr::read_rds("data/RGFCF.rds")
CTSOP        <- readr::read_rds("data/ctsop_msoa_knaresborough.rds")
SAIE         <- readr::read_rds("data/saie.rds")

sp_datasets  <- list(RGVA  = RGVA,
                     #RGVAI = RGVAI,
                     BRES  = BRES,
                     UKBC  = UKBC,
                     #RGFCF = RGFCF,
                     CTSOP = CTSOP,
                     SAIE = SAIE)

datasets <- list(# ons_datasets = ons_datasets,
                 sp_datasets = sp_datasets)

# this added to provide a second option - instead of two lists within a list
# we provide a single all_datasets list which contains ons and spatial
eddie_datasets <- c(# ons_datasets,
                    sp_datasets)
