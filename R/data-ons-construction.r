ons_process_construction <- function() {

  cons_url <- "https://www.ons.gov.uk/businessindustryandtrade/constructionindustry/datasets/outputintheconstructionindustry"

  meta <- extract_ons_metadata(cons_url)

  download.file(
    meta$files,
    "data-raw/output_in_the_construction_industry.xlsx",
    mode = "wb"
  )

  cons <- readxl::read_excel(
    "data-raw/output_in_the_construction_industry.xlsx",
    sheet = "Table 1a",
    skip = 4
  )

  lookup <- data.frame(
    variable.name = names(cons)[-1],
    variable.code = cons[1, ][-1] |> as.character()
  )

  cons_dates <- function(x) {
    out <- data.frame(
      dates.date = x,
      dates.date2 = Sys.Date(),
      dates.freq = NA_character_
    )

    for (i in 1:nrow(out)) {
      ifelse(nchar(out$dates.date[i]) == 4, {
        out$dates.date2[i] <- as.Date(paste0(out$dates.date[i], "-01-01"))
        out$dates.freq[i] <- "a"
      },
      ifelse(nchar(out$dates.date[i]) == 8, {
        out$dates.date2[i] <- as.Date(paste0(out$dates.date[i], "-01"), format = "%b %Y-%d")
        out$dates.freq[i] <- "m"
      }, {
      out$dates.date2[i] <- as.Date(paste("01", substr(out$dates.date[i], 1, 3), substr(out$dates.date[i], nchar(out$dates.date[i])-4, nchar(out$dates.date[i]))), format = "%d %b %Y")
      out$dates.freq[i] <- "q"
      }
      ))
    }
    return(out)
  }

  cons_final <- cons[-1, ] |>
    dplyr::rename(dates.date = `Time period`) |>
    dplyr::mutate(
      dates.date2 = cons_dates(dates.date)$dates.date2,
      dates.freq = cons_dates(dates.date)$dates.freq,
      .before = 1
    ) |>
    tidyr::pivot_longer(!dplyr::starts_with("dates"), names_to = "sector.name") |>
    dplyr::mutate(value = as.numeric(value)) |>
    dplyr::mutate(
      dataset = "CONS",
      variable.name = "Volume SA Index") |>
    dplyr::inner_join(lookup, by = c("sector.name" = "variable.name")) |>
    dplyr::select(
      dataset, dates.date = dates.date2, dates.freq,
      sector.name, variable.code, variable.name,
      value
    )

  arrow::write_parquet(cons_final, "data/parquet/CONS.parquet")

  # update metadata
  edd_dict$last_update[edd_dict$id == "CONS"] <- meta$last_update |> as.character()
  edd_dict$next_update[edd_dict$id == "CONS"] <- meta$next_update |> as.character()
  edd_dict$last_download[edd_dict$id == "CONS"] <- Sys.Date() |> as.character()

  # rewrite edd_dict
  readr::write_csv(edd_dict, 'data/edd_dict.csv')
}