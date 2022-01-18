fedo_object_to_dataframe <- function(fedo_object) {
  # identify all dimensions in the df that's been passed in
  dims <- names(fedo_object$dimensions)
  data <- fedo_object$data
  for (d in seq_along(dims)) {
    dimension <- fedo_object[["dimensions"]][[d]]
    data <- dplyr::left_join(
      data,
      dimension %>% dplyr::select(name, code), # the select restriction is in place until we can dynamically handle $unit, $type, etc.
      by = setNames("code", dims[d]) # evaluates to: by = c("dims[d] = "code")
    ) %>%
      # at this point it handles dim$name and dim$code, but also needs to manage $unit, $type etc. when present
      dplyr::mutate(!!dims[d] := tibble::tibble(code = !!data[[dims[d]]],
                                                name = name)
      ) %>%
      dplyr::select(-name)
  }
  return(data)
  # TODO we need to deal with the NAs in the table for datasets which do not have
  # dimensions that others do. This will happen at the "bind_rows" point
}
