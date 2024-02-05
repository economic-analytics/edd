
# Core functions ----------------------------------------------------------

generate_dimension_total <- function(df, dimension,
                                     dimension_plural = dimension) {

  vars_to_group_by <- names(df)[!grepl(paste0("^", dimension), names(df)) | names(df) == "value"]

  out_df <- df |>
    dplyr::group_by(dplyr::across(vars_to_group_by)) |>
    dplyr::summarise(value = sum(value))

  out_df[paste(dimension, "code", sep = "_")] <- "All"
  out_df[paste(dimension, "name", sep = "_")] <- paste("All", dimension_plural)

  dplyr::bind_rows(df, out_df)
}

add_hocl_msoa_names <- function(df, code_col) {

  if (!file.exists("data-raw/MSOA-Names-Latest.csv")) {
    file_url <- "https://houseofcommonslibrary.github.io/msoanames/MSOA-Names-Latest.csv"
    download.file(file_url, file.path("data-raw", basename(fileurl)))
  }

  hocl_msoa_names <- readr::read_csv("data-raw/MSOA-Names-Latest.csv") |>
      dplyr::select(msoa11cd, msoa11hclnm)

  merge(df, hocl_msoa_names,
        by.x = code_col, by.y = "msoa11cd", all.x = TRUE) |>
    dplyr::rename(geography_name.ONS = geography_name,
                  geography_name = msoa11hclnm)
}

tidy_bres <- function(df) {
  df <- df |>
    dplyr::select(date, geography_code, geography_name, industry_code, industry_name, employment_status_name, obs_value) |>
    # removed as now in data_nomis_to-df
    # tidyr::separate(INDUSTRY_NAME, c("INDUSTRY_CODE", "INDUSTRY_NAME"), " : ") |>
    tidyr::pivot_wider(names_from = employment_status_name, values_from = value) |>
    dplyr::mutate(`Other employment` = Employment - (`Full-time employees` + `Part-time employees`)) |>
    dplyr::mutate(FTE = `Full-time employees` + (0.5 * `Part-time employees`) + `Other employment`) |>
    tidyr::pivot_longer(cols = -(date:industry_name), names_to = "employment_status_name", values_to = "value") |>
    dplyr::mutate(date = as.Date(paste0(date, "-01-01"))) |>
    generate_dimension_total("industry", "industries") |>
    add_hocl_msoa_names("geography_code")

  df <- tibble::tibble(
    dates     = tibble::tibble(date = df$DATE,
                               freq = "a"),
    geography = tibble::tibble(code = df$GEOGRAPHY_CODE,
                               name = df$msoa11hclnm,
                               name.ONS = df$GEOGRAPHY_NAME,
                               type = "MSOA11"),
    industry  = tibble::tibble(code = df$INDUSTRY_CODE,
                               name = df$INDUSTRY_NAME,
                               type = "SIC07 Section"),
    variable  = tibble::tibble(code = df$EMPLOYMENT_STATUS_NAME,
                               name = df$EMPLOYMENT_STATUS_NAME,
                               unit = "Persons"),
    value = df$OBS_VALUE
  )

  return(df)
}


flatdftolistdf <- function(df) {
  df <- tibble::tibble(
    dates     = tibble::tibble(date = df$DATE,
                               freq = "a"),
    geography = tibble::tibble(code = df$GEOGRAPHY_CODE,
                               name = df$msoa11hclnm,
                               name.ONS = df$GEOGRAPHY_NAME,
                               type = "MSOA11"),
    industry  = tibble::tibble(code = df$INDUSTRY_CODE,
                               name = df$INDUSTRY_NAME,
                               type = "SIC07 Section"),
    variable  = tibble::tibble(code = df$EMPLOYMENT_STATUS_NAME,
                               name = df$EMPLOYMENT_STATUS_NAME,
                               unit = "Persons"),
    value = df$OBS_VALUE
  )
}

df_to_obj <- function(df) {
  dims <- names(df)[!names(df) %in% c("dates", "value")]

  data <- tibble::tibble(
    dates = df$dates
  )

  for (d in dims) {
    data[[d]] <- df[[d]][["code"]]
  }

  data$value <- df$value

  dimensions <- list()

  for (d in dims) {
    dimensions[[d]] <- df[[d]] |> dplyr::distinct()
  }

  obj <- list(data = data,
              dimensions = dimensions)

  return(obj)
}



# RGVA MSOA ---------------------------------------------------------------

rgva_msoa <- readRDS("~/Data/ONS/Regional Accounts/GVA/rgva_msoa.rds") |>
  dplyr::filter(geography$code %in% knaresborough_msoas) |>
  df_to_obj()

saveRDS(rgva_msoa, "data/rgva_msoa.rds")
saveRDS(rgva_msoa, "../fedo/data/rgva_msoa.rds")

# BRES --------------------------------------------------------------------

# bres_lsoa <- readr::read_csv("data-raw/bres_lsoa_sic-sections_harrogate_2015_2021.csv") |>
#   tidy_bres()

bres_msoa <- readr::read_csv("data-raw/bres_msoa_sic-sections_harrogate_2015_2021.csv") |>
  tidy_bres() |>
  dplyr::filter(geography$code %in% knaresborough_msoas) |>
  df_to_obj()


saveRDS(bres_msoa, "data/bres_msoa.rds")
saveRDS(bres_msoa, "../fedo/data/bres_msoa.rds")

# UKBC Enterprises by employee band ---------------------------------------

ukbc_ent_ind_emp <- read_csv("data-raw/ukbc_msoa_sic-sections_harrogate_employees_sector.csv") |>
  select(DATE, GEOGRAPHY_CODE, GEOGRAPHY_NAME, INDUSTRY_CODE, INDUSTRY_NAME, EMPLOYMENT_SIZEBAND_NAME, LEGAL_STATUS_NAME, OBS_VALUE) |>
  separate(INDUSTRY_NAME, c("INDUSTRY_CODE", "INDUSTRY_NAME"), " : ") |>
  mutate(DATE = as.Date(paste0(DATE, "-01-01"))) |>
  filter(!is.na(OBS_VALUE)) |>
  filter(GEOGRAPHY_CODE %in% knaresborough_msoas) |>
  add_hocl_msoa_names("GEOGRAPHY_CODE")

ukbc_ent_ind_emp <- tibble::tibble(
  dates = tibble::tibble(date = ukbc_ent_ind_emp$DATE,
                         freq = "a"),
  geography = tibble::tibble(code = ukbc_ent_ind_emp$GEOGRAPHY_CODE,
                             name = ukbc_ent_ind_emp$msoa11hclnm,
                             name.ONS = ukbc_ent_ind_emp$GEOGRAPHY_NAME,
                             type = "MSOA11"),
  industry = tibble::tibble(code = ukbc_ent_ind_emp$INDUSTRY_CODE,
                            name = ukbc_ent_ind_emp$INDUSTRY_NAME),
  employment_sizeband = tibble::tibble(code = ukbc_ent_ind_emp$EMPLOYMENT_SIZEBAND_NAME,
                                       name = ukbc_ent_ind_emp$EMPLOYMENT_SIZEBAND_NAME),
  legal_status = tibble::tibble(code = ukbc_ent_ind_emp$LEGAL_STATUS_NAME,
                                name = ukbc_ent_ind_emp$LEGAL_STATUS_NAME),
  variable = tibble::tibble(code = "Enterprises",
                            name = "Enterprises"),
  value = ukbc_ent_ind_emp$OBS_VALUE)

# UKBC Enterprises by turnover band ---------------------------------------

ukbc_ent_ind_turn <- read_csv("data-raw/ukbc_msoa_sic-sections_harrogate_turnover_sector.csv") |>
  select(DATE, GEOGRAPHY_CODE, GEOGRAPHY_NAME, INDUSTRY_CODE, INDUSTRY_NAME, TURNOVER_SIZEBAND_NAME,
         LEGAL_STATUS_NAME, OBS_VALUE) |>
  separate(INDUSTRY_NAME, c("INDUSTRY_CODE", "INDUSTRY_NAME"), " : ") |>
  mutate(DATE = as.Date(paste0(DATE, "-01-01"))) |>
  filter(GEOGRAPHY_CODE %in% knaresborough_msoas) |>
  add_hocl_msoa_names("GEOGRAPHY_CODE")

ukbc_ent_ind_turn <- tibble::tibble(
  dates = tibble::tibble(date = ukbc_ent_ind_turn$DATE,
                         freq = "a"),
  geography = tibble::tibble(code = ukbc_ent_ind_turn$GEOGRAPHY_CODE,
                             name = ukbc_ent_ind_turn$msoa11hclnm,
                             name.ONS = ukbc_ent_ind_turn$GEOGRAPHY_NAME,
                             type = "MSOA11"),
  industry = tibble::tibble(code = ukbc_ent_ind_turn$INDUSTRY_CODE,
                            name = ukbc_ent_ind_turn$INDUSTRY_NAME),
  turnover_sizeband = tibble::tibble(code = ukbc_ent_ind_turn$TURNOVER_SIZEBAND_NAME,
                                       name = ukbc_ent_ind_turn$TURNOVER_SIZEBAND_NAME),
  legal_status = tibble::tibble(code = ukbc_ent_ind_turn$LEGAL_STATUS_NAME,
                                name = ukbc_ent_ind_turn$LEGAL_STATUS_NAME),
  variable = tibble::tibble(code = "Enterprises",
                            name = "Enterprises"),
  value = ukbc_ent_ind_turn$OBS_VALUE)

# UKBC Local units by employee band ---------------------------------------

ukbc_units_ind_emp <- read_csv("data-raw/ukbc_msoa_sic-sections_local-units_harrogate_employees_sector.csv") |>
  select(DATE, GEOGRAPHY_CODE, GEOGRAPHY_NAME, INDUSTRY_CODE, INDUSTRY_NAME, EMPLOYMENT_SIZEBAND_NAME,
         LEGAL_STATUS_NAME, OBS_VALUE) |>
  separate(INDUSTRY_NAME, c("INDUSTRY_CODE", "INDUSTRY_NAME"), " : ") |>
  mutate(DATE = as.Date(paste0(DATE, "-01-01"))) |>
  filter(GEOGRAPHY_CODE %in% knaresborough_msoas) |>
  add_hocl_msoa_names("GEOGRAPHY_CODE")

ukbc_units_ind_emp <- tibble::tibble(
  dates = tibble::tibble(date = ukbc_units_ind_emp$DATE,
                         freq = "a"),
  geography = tibble::tibble(code = ukbc_units_ind_emp$GEOGRAPHY_CODE,
                             name = ukbc_units_ind_emp$msoa11hclnm,
                             name.ONS = ukbc_units_ind_emp$GEOGRAPHY_NAME,
                             type = "MSOA11"),
  industry = tibble::tibble(code = ukbc_units_ind_emp$INDUSTRY_CODE,
                            name = ukbc_units_ind_emp$INDUSTRY_NAME),
  employment_sizeband = tibble::tibble(code = ukbc_units_ind_emp$EMPLOYMENT_SIZEBAND_NAME,
                                       name = ukbc_units_ind_emp$EMPLOYMENT_SIZEBAND_NAME),
  legal_status = tibble::tibble(code = ukbc_units_ind_emp$LEGAL_STATUS_NAME,
                                name = ukbc_units_ind_emp$LEGAL_STATUS_NAME),
  variable = tibble::tibble(code = "Local Units",
                            name = "Local Units"),
  value = ukbc_units_ind_emp$OBS_VALUE)

# UKBC combined -----------------------------------------------------------

# list(ent = ukbc_ent_ind_emp,
#      units = ukbc_units_ind_emp) |>
#   bind_rows(.id = "type") |>
#   filter(legal_status$name == "Total",
#          employment_sizeband$name == "Total") |>
#   group_by(dates, geography, type) |>
#   summarise(value = sum(value, na.rm = TRUE)) |>
#   ggplot(aes(x = dates$date, y = value, colour = type)) +
#   geom_line() +
#   facet_wrap(~ geography$name)

ukbc <- list(ent_emp = ukbc_ent_ind_emp,
             ent_turn = ukbc_ent_ind_turn,
             units_emp = ukbc_units_ind_emp)

ukbc_l <- dplyr::bind_rows(ukbc, .id = "dataset") |>
  tidyr::pivot_longer(cols = c(EMPLOYMENT_SIZEBAND_NAME, TURNOVER_SIZEBAND_NAME), names_to = "sizeband_type", values_to = "sizeband", values_drop_na = TRUE) |>
  generate_industry_total()


ukbc_l <- tibble::tibble(
  dates = tibble::tibble(date = ukbc_l$DATE,
                         freq = "a"),
  geography = tibble::tibble(code = ukbc_l$GEOGRAPHY_CODE,
                             name = ukbc_l$msoa11hclnm,
                             name.ONS = ukbc_l$GEOGRAPHY_NAME,
                             type = "MSOA11"),
  industry = tibble::tibble(code = ukbc_l$INDUSTRY_CODE,
                            name = ukbc_l$INDUSTRY_NAME,
                            type = "SIC07 Section"),
  sizeband_type = tibble::tibble(code = ukbc_l$sizeband_type,
                                 name = ukbc_l$sizeband_type),
  sizeband = tibble::tibble(code = ukbc_l$sizeband,
                            name = ukbc_l$sizeband),
  legal_status = tibble::tibble(code = ukbc_l$LEGAL_STATUS_NAME,
                                name = ukbc_l$LEGAL_STATUS_NAME),
  variable = tibble::tibble(code = ifelse(ukbc_l$dataset == "units_emp",
                                          "Number of local units",
                                          "Number of enterprises"),
                            name = ifelse(ukbc_l$dataset == "units_emp",
                                          "Number of local units",
                                          "Number of enterprises")),
  value = ukbc_l$OBS_VALUE
)

ukbc_final <- df_to_obj(ukbc_l)

saveRDS(ukbc_final, "data/ukbc_knaresborough.rds")
saveRDS(ukbc_final, "../fedo/data/ukbc_knaresborough.rds")

# Council Tax Stock of Properties -----------------------------------------

ctsop <- readRDS("~/Data/VOA/CTSOP/ctsop_msoa.rds")
ctsop$data <- ctsop$data |>
  dplyr::filter(geography %in% knaresborough_msoas)
ctsop$dimensions$geography <- ctsop$dimensions$geography |>
  dplyr::filter(code %in% knaresborough_msoas)

saveRDS(ctsop, "data/ctsop_knaresborough.rds")

# SAIE ----------------------------------------

saie <- readRDS("~/Data/ONS/Regional Accounts/GDHI/SAIE/saie.rds")
saie <- dplyr::filter(saie, geography$code %in% knaresborough_msoas)
saie <- df_to_obj(saie)
saveRDS(saie, "data/saie_knaresborough.rds")

# Population --------------------------------------------------------------

sape_msoa <- readRDS("~/Data/ONS/Population/sape_msoa.rds")
sape_msoa$data <- dplyr::filter(sape_msoa$data,
                                geography %in% knaresborough_msoas)
sape_msoa$dimensions$geography <- dplyr::filter(sape_msoa$dimensions$geography, code %in% knaresborough_msoas)

saveRDS(sape_msoa, "data/sape_knaresborough.rds")

# HPSSA -------------------------------------------------------------------

hpssa2 <- readRDS("~/Data/ONS/HPSSA/hpssa2.rds")
hpssa2$data <- dplyr::filter(hpssa2$data, geography %in% knaresborough_msoas)
hpssa2$dimensions$geography <- dplyr::filter(hpssa2$dimensions$geography, code %in% knaresborough_msoas)

saveRDS(hpssa2, "data/HPSSA2_knaresborough.rds")
