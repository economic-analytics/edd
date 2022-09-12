update_eddie_dict_from_csv <- function() {
  eddie_dict <- readr::read_csv("data-raw/eddie_dict.csv",
                               col_types = readr::cols(.default = readr::col_character(),
                                                       status = readr::col_logical(),
                                                       obj_available = readr::col_logical()))
  usethis::use_data(eddie_dict, overwrite = TRUE)
}
