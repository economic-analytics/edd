# Regional FDI
# https://www.ons.gov.uk/releases/foreigndirectinvestmentexperimentaluksubnationalestimatesoctober2022

RFDI_in_path <- "data-raw/20221011subnatinwardtablesfinal3.xlsx"
RFDI_in_sheets <- readxl::excel_sheets(RFDI_in_path)
RFDI_in_sheets <- RFDI_in_sheets[grepl("^[0-9]{1}\\.[0-9]{1-2}",
                                       RFDI_in_sheets)]

RFDI_out_path <- "data-raw/20221011subnatoutwardtablesfinal1.xlsx"
RFDI_out_sheets <- readxl::excel_sheets(RFDI_out_path)
RFDI_out_sheets <- RFDI_out_sheets[grepl("^[0-9]{1}\\.[0-9]{1-2}",
                                       RFDI_out_sheets)]

if (!identical(RFDI_in_sheets, RFDI_out_sheets)) {
  stop("Sheet names do not match")
}


RFDI_in <- lapply(RFDI_in_sheets, function(sht) {
  readxl::read_excel(RFDI_in_path,
                     sheet = sht,
                     na = c("c", "low"),
                     skip = 3)
}) |>
  setNames(RFDI_in_sheets) |>
  dplyr::bind_rows(.id = "sheet") |>
  dplyr::mutate(geography_name =
                  dplyr::coalesce(`Region name`, `City region`)) |>
  dplyr::select(-c(`Region name`)) |>
  dplyr::mutate(geography_code =
                  dplyr::coalesce(`ITL1 code`, `ITL2 code`, `City region`)) |>
  dplyr::select(-c(`ITL1 code`, `ITL2 code`, `City region`)) |>
  dplyr::mutate(type = sub("^((?:\\S+\\s+){2}(\\S+){1}).*", "\\2", sheet)) |>
  dplyr::mutate(`No grouping` = ifelse(is.na(`Country/continent`) &
                                         is.na(`Industrial activity`) &
                                         is.na(`Industrial group`),
                                       "Total", NA)) |>
  tidyr::pivot_longer(cols = c(`Country/continent`,
                               `Industrial activity`,
                               `Industrial group`,
                               `No grouping`),
                      names_to = "grouping",
                      values_to = "grouping_type",
                      values_drop_na = TRUE)

names(RFDI_in) <- sub(" \r\n(£ million)", "", names(RFDI_in), fixed = TRUE)
RFDI_in <- RFDI_in |>
  tidyr::pivot_longer(cols = tidyselect:::where(is.numeric), names_to = "date") |>
  dplyr::rename(variable_name = Measure,
                type_name = type,
                grouping_name = grouping,
                grouping_type_name = grouping_type) |>
  dplyr::select(-sheet) |>
  dplyr::mutate(variable_code = variable_name,
                type_code = type_name,
                grouping_code = grouping_name,
                grouping_type_code = grouping_type_name)

RFDI_in <- df_to_edd_df(RFDI_in)
RFDI_in <- edd_df_to_edd_obj(RFDI_in)
saveRDS(RFDI_in, "data/datasets/RFDI.rds")




#############################################

RFDI_out <- lapply(RFDI_out_sheets, function(sht) {
  readxl::read_excel(RFDI_out_path, sheet = sht, na = c("c", "low"), skip = 3)
}) |> setNames(RFDI_out_sheets) |> dplyr::bind_rows(.id = "sheet")

RFDI <- dplyr::bind_rows(list(inward = RFDI_in,
                              outward = RFDI_out),
                         .id = "direction")

