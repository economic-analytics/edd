update_onspd <- function(path = NULL) {
  if (is.null(path)) {
    path <- "~/Data/Geodata/ONSPD"
  }

  onspd_files <- list.files(path)
  onspd_dates <- gsub('ONSPD_|_UK', '', onspd_files)
  most_recent <- sort(decreasing = TRUE, as.Date(paste("1", onspd_dates), format = "%d %b_%Y"))[1]
}
