
push_to_sql <- function(con, df, dest_table, batch_size = 100000) {
  nrows <- nrow(df)
  seq <- seq(1, nrows, by = batch_size)

  for (i in seq_along(seq)) {
    if (i != length(seq)) {
      if (!DBI::dbExistsTable(conn = con, name = dest_table)) {
        DBI::dbCreateTable(conn = con,
                           name = dest_table,
                           fields = df)
      }
        DBI::dbAppendTable(conn = con,
                           name = dest_table,
                           value = df[seq[i]:(seq[i + 1] - 1), ])
        message("Pushed ", seq[i] + batch_size - 1, " rows of ", nrows)
    } else {
      DBI::dbAppendTable(conn = con,
                         name = dest_table,
                         value = df[seq[i]:nrow(df), ])
      message("Pushed ", nrows, " rows of ", nrows)
      message("Completed.")
    }
  }
  dplyr::tbl(con, dest_table)
}
