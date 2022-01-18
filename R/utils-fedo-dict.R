update_fedo_dict_from_csv <- function() {
  fedo_dict <- readr::read_csv("data-raw/fedo_dict.csv",
                               col_types = readr::cols(.default = readr::col_character(),
                                                       status = readr::col_logical(),
                                                       obj_available = readr::col_logical()))
  usethis::use_data(fedo_dict, overwrite = TRUE)
}
