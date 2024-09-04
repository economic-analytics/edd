datasets_to_update <- function() {
  edd_dict |>
    dplyr::filter(
      status &
      next_update <= Sys.Date() &
      next_update >= last_download
    ) |>
    dplyr::select(id)
}

check_next_update_dates <- function() {
  datasets_with_no_next_update <- edd_dict |>
    dplyr::filter(
      status &
      is.na(next_update) &
      !is.na(page_url) &
      grepl("ons.gov.uk", page_url)
    )

  for (id in datasets_with_no_next_update$id) {
    meta <- extract_ons_metadata(datasets_with_no_next_update$page_url[datasets_with_no_next_update$id == id])
    Sys.sleep(2)
    if (!is.na(meta$next_update)) {
      update_edd_dict(id, "next_update", meta$next_update)
      message("Successfully found next update date of ", meta$next_update, " for dataset ", id)
    }
  }
}
