merge_column_names <- function(df,
                               name_rows,
                               first_data_row = NULL,
                               sep = " ",
                               drop_name_rows = TRUE) {
  if (is.data.frame(df) & is.vector(name_rows) & is.integer(name_rows)) {
    if (is.null(first_data_row) & nrow(df) > max(name_rows)) {
      first_data_row <- max(name_rows) + 1
    }

    rows_to_merge <- df[name_rows, ] |>
      t() |>
      as.data.frame() |>
      tidyr::fill(dplyr::everything()) |>
      t() |>
      as.data.frame()

    new_names <- character()
    for (i in seq_along(1:nrow(rows_to_merge))) {
      new_names <- paste(new_names, rows_to_merge[i, ], sep = sep)
    }

    new_names <- stringr::str_remove_all(new_names, "NA") |>
      stringr::str_remove_all(paste0("^", sep, "+")) |>
      # This removes typical ONS superscript footnotes by finding all words that
      # end with a digit and removing the digit
      stringr::str_replace_all("([A-Za-z])\\d\\b", "\\1") |>
      stringr::str_squish()

    if (!is.null(first_data_row)) {
      df <- df[-(1:first_data_row - 1), ]
    }

    if (drop_name_rows) {
      df <- df[-name_rows, ]
    }

    names(df) <- new_names
    unnamed_columns <- stringr::str_which(new_names, "^$")
    if (length(unnamed_columns) >= 1) {
      message("Column indices ", toString(stringr::str_which(new_names, "^$")), " have no names.")
      q <- readline("Do you want to add those names now? (Y/N) ")
      if (toupper(q) == "Y") {
        for (i in seq_along(1:length(unnamed_columns))) {
          names(df)[i] <- readline(paste0("Please enter name for column ", unnamed_columns[i], ": "))
        }
      }
    }
    return(df)
  }
}
