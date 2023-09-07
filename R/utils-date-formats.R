# TODO all functions here need editing and unifying
# TODO need to handle half years, too (e.g. 2020H1)


date_iso_to_text <- function(date, frequency = c("a", "q", "m"), abbr_month = TRUE) {
  if (frequency == "a") {
    return(format.Date(date, "%Y"))
  }

  if (frequency == "q") {
    return(paste(paste0("Q", date_iso_to_quarter(date)),
                 format.Date(date, "%Y")
                 )
    )
  }

  if (frequency == "m") {
    if (abbr_month) {
      month_name <- month.abb[as.integer(format.Date(date, "%m"))]
    } else {
      month_name <- month.name[as.integer(format.Date(date, "%m"))]
    }
    return(paste(month_name, format.Date(date, "%Y"))
    )
  }
}

date_iso_to_quarter <- function(date) {
  return(ceiling(as.integer(format.Date(date, "%m")) / 3))
}

date_text_to_iso <- function(date_as_text) {
  out <- character(length = length(date_as_text))
  for (i in seq_along(date_as_text)) {
    # 01-01-2000
    if (grepl('[0-9]{1,2}-[0-9]{2}-[0-9]{4}', date_as_text[i])) {
      out[i] <- as.Date(date_as_text[i], format = '%d-%m-%Y') |>
        as.character()
      next
    }
    # [0]1 Jan/January 2000
    if (grepl('[0-9]{1,2} [A-Za-z]{3,} [0-9]{4}', date_as_text[i])) {
      out[i] <- as.Date(date_as_text[i], format = '%d %b %Y') |>
        as.character()
      next
    }
    # [0]1 Jan/January (no year provided)
    # if month < current month, use next year, else use this year
    # TODO this should be if date < current date, use next year, else this year
    if (grepl('^[0-9]{1,2} [A-Za-z]{3,}$', date_as_text[i])) {
      month_text <- stringr::str_extract(date_as_text[i], '[A-Za-z]{3,}')
      if (nchar(month_text) == 3) {
        month_integer <- which(month.abb == month_text)
      } else {
        month_integer <- which(month.name == month_text)
      }

      year <- if (month_integer < lubridate::month(Sys.Date())) {
        lubridate::year(Sys.Date()) + 1
      } else {
        lubridate::year(Sys.Date())
      }
      out[i] <- as.Date(paste(date_as_text[i], year), format = '%d %b %Y') |>
        as.character()
      next
    }
    # January 2020 (i.e. no day provided) - write YYYY-MM
    if (grepl('[A-Za-z]{3,} [0-9]{4}', date_as_text[i])) {
      month_text <- stringr::str_extract(date_as_text[i], '[A-Za-z]{3,}')
      if (nchar(month_text) == 3) {
        month_integer <- which(month.abb == month_text)
      } else {
        month_integer <- which(month.name == month_text)
      }

      # ensure we return a two-digit month
      if (month_integer < 10) {
        month_integer <- paste0('0', month_integer)
      }

      year <- stringr::str_extract(date_as_text[i], '[0-9]{4}')

      out[i] <- paste(year, month_integer, sep = "-")
      next
    }
    # catch all - can't match anything
    out[i] <- NA
  }
  return(out)
}

# date_text_to_df <- function(dates) {
#   message("Parsing date formats (can be slow) ...")
#   # if the date is four digits only, i.e. a year and annual
#   out_df <- purrr::map_df(dates, function(d) {
#     if (grepl("^[0-9]{4}$", d)) {
#       date <- readr::parse_date(d, format = "%Y")
#       freq <- "a"
#     } else if (grepl("Q", d)) { # if the date contains a "Q", i.e. quarterly
#       date <- lubridate::yq(d)
#       freq <- "q"
#     } else if (grepl("[0-9]{2}-[0-9]{2}-[0-9]{4}", d)) { # if the date is DD-MM-YYYY
#       date <- as.Date(d, format = "%d-%m-%Y")
#       freq <- "d"
#     } else if (grepl("[0-9]{4}$", d)) { # if contains four digits at the end
#       date <- lubridate::my(d)
#       freq <- "m"
#     } else if (grepl("^[0-9]{4}", d)) { # if it contains four digits at the beginning
#       date <- lubridate::ymd(d, truncated = 1)
#       freq <- "m"
#     } else {
#       date <- as.Date(NA) # if none of the above parse, return an NA to highlight the problem
#       freq <- NA_character_
#     }
#     df <-  tibble::tibble(date = date,
#                           freq = freq)
#   })
#   message("Done.")
#   return(out_df)
# }

# NEW VERSION OF THE ABOVE

date_text_to_df <- function(dates) {

  #stopifnot(is.vector(dates), "`dates` is not a vector")

  if (class(dates) == "Date") {
    stop("`dates` already has `class()` of `Date`. Cannot impute frequency")
  }

  if (!is.character(dates)) {
    dates2 <- as.character(dates)
    if (all(dates == dates2)) {
      dates <- dates2
    } else {
      stop("`dates` cannot be coerced to a character vector")
    }
  }

  message("Parsing date formats ...")

  n <- length(dates)
  dates_df <- data.frame(original_date = dates)
  dates_df$order <- 1:n
  dates_df <- dates_df |>
    dplyr::arrange(original_date)

  # prepare output vectors
  date <- vector(length = n)
  freq <- character(length = n)

  parse_dates <- function(d) {
    # if the date is four digits only, i.e. a year and annual
    if (grepl("^[0-9]{4}$", d)) {
      date <- readr::parse_date(d, format = "%Y")
      freq <- "a"
    } else if (grepl("Q", d)) { # if the date contains a "Q", i.e. quarterly
      date <- lubridate::yq(d)
      freq <- "q"
    } else if (grepl("[0-9]{2}-[0-9]{2}-[0-9]{4}", d)) { # if the date is DD-MM-YYYY
      date <- as.Date(d, format = "%d-%m-%Y")
      freq <- "d"
    } else if (grepl("[0-9]{4}$", d)) { # if contains four digits at the end
      date <- lubridate::my(d)
      freq <- "m"
    } else if (grepl("^[0-9]{4}", d)) { # if it contains four digits at the beginning
      date <- lubridate::ymd(d, truncated = 1)
      freq <- "m"
    } else {
      date <- as.Date(NA) # if none of the above parse, return an NA to highlight the problem
      freq <- NA_character_
    }
    df <-  tibble::tibble(date = date,
                          freq = freq)
    return(df)
  }

  # iterate through `dates`
  previous_date <- ""
  for (d in 1:n) {

    if (previous_date != dates_df$original_date[d]) {
      temp_df <- parse_dates(dates_df$original_date[d])
    }

    date[d] <- temp_df$date
    freq[d] <- temp_df$freq
    previous_date <- dates_df$original_date[d]
  }



  dates_df$date <- as.Date(date)
  dates_df$freq <- freq

  dates_df <- dates_df |>
    dplyr::arrange(order) |>
    dplyr::select(date, freq) |>
    tibble::as_tibble()


  message("Done.")
  return(dates_df)

}



# DEPRECATED

# ons_parse_dates <- function(dates,
#                             format = c("df", "vector"),
#                             frequency = FALSE) {
#   format <- match.arg(format)
#
#   if (grepl("^[0-9]{4}$", dates)) { #if 4 digit number
#     date <- readr::parse_date(dates, format = "%Y")
#     freq <- "a"
#   } else if (grepl("Q", dates)) { #if contains 'Q'
#     date <- lubridate::yq(dates)
#     freq <- "q"
#   } else if (grepl("[0-9]{4}$", dates)) {
#     date <- lubridate::dmy(dates, truncated = 1)
#     freq <- "m"
#   } else if (grepl("^[0-9]{4}", dates)) {
#     date <- lubridate::ymd(dates, truncated = 1)
#     freq <- "m"
#   } else {
#     date <- as.Date(NA)
#     freq <- NA_character_
#   }
#
#   if (frequency && format == "df") {
#     df <- tibble::tibble(date = date, freq = freq)
#   } else if (format == "df" && !frequency) {
#     df <- tibble::tibble(date = date)
#   } else if (format == "vector") {
#     df <- date
#   }
#   return(df)
# }
