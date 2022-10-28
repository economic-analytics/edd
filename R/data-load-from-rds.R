dataFileLocation <- "data/datasets"

dataFiles <- list.files(dataFileLocation, full.names = TRUE)

eddie_datasets <- lapply(dataFiles, function(file) {
  readRDS(file)
}) |>
  setNames(tools::file_path_sans_ext(basename(dataFiles)))
