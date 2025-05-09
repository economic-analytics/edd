validate_postcode <- function(x) {
  grepl("^[A-Z]{1,2}[0-9]{1,2}[A-Z]{0,1} {1}[0-9]{1}[A-Z]{2}", x)
}
