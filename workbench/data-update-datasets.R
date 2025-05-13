# main function which executes the full updating process
update_datasets <- function(force_update_all = FALSE) {
  meta <- verify_metadata()
  to_update <- datasets_to_update()
  update_dataset(to_update)
    download_dataset()
    dataset_is_updated()
    process_dataset()
    verify_dataset()
    write_dataset()
    update_edd_dict()
}

verify_metadata <- function() {
  # this should call extract_ons_metadata() which will return an object that
  # needs capturing (rename to get_ons_metadata())
  check_next_update_dates()

  # if this object contains differences from edd_dict, write these to edd_dict
}

datasets_to_update <- function() {
  ids <- subset(
    edd_dict,
    edd_dict$type == "dataset" &
      edd_dict$status &
      edd_dict$next_update <= Sys.Date() &
      edd_dict$next_update > edd_dict$last_download &
      # TODO should this also test for existence of function and its validity?
      !is.na(edd_dict$func)
  )[["id"]]

  if (length(ids) == 0) {
    message("All datasets are up-to-date")
    return(invisible())
  }

  message("These datasets will be updated: ", paste(ids, collapse = ", "))
  return(ids)
}

# iterate through this vector, calling a generic update_dataset(id) function,
# passing edd_dict$id

update_dataset <- function(ids) {
  if (is.null(ids) || length(ids) == 0) {
    return(invisible())
  }

  for (id in ids) {
    local_path <- download_dataset(id)
    # 5. if error, display, add flag to edd_dict, next id
    # 6. if success, call process_dataset(id)
    # 7. process_dataset(id) should now invoke edd_dict$func
    # 8. # 1. using id, lookup edd_dict$func
    # this uses the script from func to process the file, returning a data.frame
    # 9. data frame should be verified for appropriate columns, etc
    # 10. if verified, add edd_obj class to object
    # 11. call write_dataset(object)
    # 12. this should write the parquet file with message
    # 13. update the metadata in edd_dict with message
    # 14. update edd_dict$objavail to TRUE
    # 15. update edd_dict$status to TRUE
  }

}

download_dataset <- function(dataset_id, url = NULL) {
  if (is.null(url)) {
    # TODO this should also run a check against the metadata object
    url <- edd_dict$url[edd_dict$id == dataset_id]
  }

  destfile <- file.path("data-raw", basename(url))
  message("Attempting download of ", dataset_id)
  download_status <- download.file(url = url, destfile = destfile, mode = "wb")
  if (download_status == 0) {
    message(basename(url), " download successful")
    return(destfile)
    # check md5sum against original file to see if changed
    # TODO may be better to store the hash in edd_dict on download
    # if it has ...
    # update_edd_dict
  } else {
    warning("Download of ", basename(url), " failed.")
    invisible()
  }
}

dataset_is_updated <- function() {

}

process_dataset <- function(dataset_id, file = NULL) {
  process_function <- edd_dict$func[edd_dict$id == dataset_id]

  # TODO currently only ONS "standard" dataset process func has the id argument
  processed <- do.call(process_function, list(dataset_id = dataset_id))
  return(processed)
}

verify_dataset <- function(processed, dataset_id) {
  # verifications to go here
  if (TRUE) {
    class(processed) <- c(class(processed), "edd_dataset")
    return(processed)
  }

  warning(dataset_id, " is not a valid edd_dataset object.")
  return(verification_errors)
}

write_dataset <- function(edd_obj, dataset_id) {
  message("Writing ", dataset_id)
  arrow::write_parquet(
    edd_obj,
    file.path("data", "parquet", paste0(dataset_id, ".parquet"))
  )
  message("DONE")
}

update_metadata <- function(dataset_id, meta) {

}

verify_dataset_file <- function() {
  # check has required column names
  # check optional column names have .code and .name
}

# edd_dict verification
# status == TRUE if:
# - func exists
# - a meta object can be returned from get_ons_metadata(page_url)
# - local_path exists
# }