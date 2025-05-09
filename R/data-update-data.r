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
  d <- edd_dict |>
    dplyr::filter(
      status &
      provider == "ONS" &
      (is.na(next_update) | next_update < last_download | next_update < Sys.Date()) &
      !is.na(page_url) &
      grepl("ons.gov.uk", page_url)
    )

  for (id in d$id) {
    cat("Looking up", id, "page", "...")
    tryCatch({
      meta <- extract_ons_metadata(
        d$page_url[
          d$id == id
        ]
      )
      cat("OK\n")
      # catches if an update has happened but we didn't get it
      if (meta$last_update > d$last_download[d$id == id]) {
        update_edd_dict(id, "last_update", meta$last_update)
        update_edd_dict(id, "next_update", meta$last_update)
        message(
          "EDD's version of ", id, " is from ", d$last_download[d$id == id],
          "\n",
          "An update of ", id, " occurred on ", meta$last_update,
          " and we'll get it this time."
        )
      } else {
        if (is.na(meta$next_update) | is.na(d$next_update[d$id == id]) | meta$next_update != d$next_update[d$id == id]) {
          update_edd_dict(id, "next_update", meta$next_update)
          message(
            "Next update date of ", id,
            " identified for ", meta$next_update
          )
        }
      }
    },
    error = function(e) {
      cat("ERROR with dataset", id, ":", conditionMessage(e), "\n")
    }
    )
    # manage rate-limiting
    Sys.sleep(2)
  }
}
