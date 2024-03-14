rgva <- readRDS("data/datasets/RGVA.rds")

rgvaShare  <- rgva |>
  edd_obj_to_dataframe() |>
  tidyr::unnest(names_sep = "_") |>
  # latest year
  dplyr::filter(dates_date == max(dates_date)) |>
  # constant prices
  dplyr::filter(variable_code == "constant") |>
  # calculate industry share as share of total for the same geog
  dplyr::group_by(geography_code) |>
  dplyr::mutate(share = value / value[industry_code == "Total"])

rgvaShare |>
  dplyr::filter(geography_name == "Leeds") |>
  dplyr::filter(grepl("^[A-Z]{1} ", industry_code)) |>
  ggplot2::ggplot(ggplot2::aes(x = industry_name, y = share)) +
  ggplot2::geom_col() +
  ggplot2::coord_flip()

# lq

rgvaShare |>
  dplyr::filter(geography_name %in% c("Manchester", "Leeds")) |>
  dplyr::filter(grepl("^[A-Z]{1} ", industry_code)) |>
  dplyr::inner_join(
    rgvaShare |> dplyr::filter(geography_code == "UK"),
    by = names(rgvaShare)[grepl("dates|industry|variable", names(rgvaShare))]
  ) |>
  dplyr::mutate(lq = share.x / share.y) |>
  ggplot2::ggplot(ggplot2::aes(x = industry_name, y = lq, fill = lq > 1)) +
  ggplot2::geom_col() +
  ggplot2::geom_point(ggplot2::aes(y = share.x * 10), size = 3) +
  ggplot2::coord_flip() +
  ggplot2::geom_hline(yintercept = 1, colour = "red") +
  ggplot2::facet_wrap("geography_name.x")

# bres
# gb, itl1, itl2, itl3
# signed link - signature can be public as applies only to this call
# needed as result is >25k rows
# TODO NB pulling GB data from BRES. rgva needs to have NI removed
url <- "https://www.nomisweb.co.uk/api/v01/dataset/NM_189_1.data.csv?geography=2092957698,1841299457...1841299467,1837105153...1837105192,1832910849...1832911016&industry=150994945...150994965&employment_status=1&measure=1&measures=20100&signature=NPK-80b58859b490b5cdc78ea9:0xfbb779d47ca98ee3ce0f3815b8c817909d428f3e"

bres  <- data_nomis_to_df(url)

gb <- names(bres)[!grepl("value|industry", names(bres))]

bres2 <- bres |>
  # this calculates a total for all industries at each date/geog combo
  dplyr::group_by(date, geography_code, geography_name, geography_type) |>
  dplyr::summarise(industry_code = "Total", industry_name = "All industries", value = sum(value)) |>
  dplyr::bind_rows(bres) |>
  # convert date
  dplyr::mutate(date = as.Date(paste0(date, "-01-01"))) |>
  dplyr::mutate(
  # convert nomis NUTS16 codes to ITL23 codes
  geography_code = stringr::str_replace(geography_code, "UK", "TL"),
  # TODO temporary hack - this isn't UK data but GB
  geography_code = ifelse(geography_code == "K03000001", "UK", geography_code))

bresShare <- bres2 |>
  # filter dates to match rgva (2021)
  dplyr::filter(date == "2021-01-01") |>
  dplyr::group_by(geography_code) |>
  dplyr::mutate(share = value / value[industry_code == "Total"])

bresShare |>
  dplyr::filter(geography_name %in% c("Bradford", "Leeds", "York")) |>
  #dplyr::filter(grepl("^[A-Z]{1} ", industry_code)) |>
  dplyr::inner_join(
    bresShare |> dplyr::filter(geography_code == "UK"),
    by = names(bresShare)[grepl("dates|industry|variable", names(bresShare))]
  ) |>
  dplyr::mutate(lq = share.x / share.y) |>
  # drop Total industries rows
  dplyr::filter(!industry_code %in% c("Total", "T")) |>
  ggplot2::ggplot(ggplot2::aes(x = industry_name, y = lq, fill = lq > 1)) +
  ggplot2::geom_col() +
  ggplot2::geom_point(ggplot2::aes(y = share.x * 10), size = 3, show.legend = F) +
  ggplot2::coord_flip() +
  ggplot2::geom_hline(yintercept = 1, colour = "red") +
  ggplot2::facet_wrap("geography_name.x") +
  ggplot2::scale_y_continuous(
    sec.axis = ggplot2::sec_axis(~ . * 10, name = "Employment share (dots) (%)")
    ) +
  ggplot2::labs(
    title = "Employment Location Quotient and Share of Employment",
    subtitle = "By SIC2007 Sector",
    y = "Location Quotient (employment) (bars)") +
    ggplot2::theme_minimal()

# generalise the above

calculate_proportions <- function(dataset, variable_name1, group_by, date = NULL) {
  # retrieve and prepare
  df <- get(dataset) |>
    edd_obj_to_dataframe() |>
    tidyr::unnest(names_sep = "_")
  
  # filter for appropriate year. If is.null(date), use most recent by default
  if (is.null(date)) {
    df <- df |>
      dplyr::filter(dates_date == max(dates_date))
  }
  
  df <- df |>
    # filter for variable
    dplyr::filter(variable_name == variable_name1) |>
    # grouping
    dplyr::group_by(dplyr::across(c(dplyr::all_of(group_by), dates_date))) |>
    # calculate shares
    dplyr::mutate(share = value / value[industry_code == "Total"])

  return(df)
}

calculate_proportions("rgva", "Constant prices", "geography_code") |> View()

##########

calculate_lq <- function(edd_obj) {
  edd_obj |>
    dplyr::inner_join(
      edd_obj |>
        dplyr::filter(geography_code == "UK"),
      by = names(edd_obj)[grepl("dates|industry|variable", names(edd_obj))]
    )
}

calculate_lq(bresShare) |> View()
total <- r1 |>
  # single letter code industries only
  dplyr::filter(grepl("Total", industry_code))
  
industries <- r1 |>
  dplyr::filter(grepl("^[A-Z]{1} ", industry_code))

uk <- r1 |>
  dplyr::filter(geography_code == "UK") |>
  dplyr::mutate(share = value / value[industry_code == "Total"])

join_names <- names(r1)[!grepl("value", names(r1))]

joined <- dplyr::inner_join(
  industries, total, by = c("geography_code")
) |>
  dplyr::mutate(share = value.x / value.y * 100)

joined |>
  dplyr::filter(geography_name.x %in% c("Leeds", "West Yorkshire")) |>
ggplot2::ggplot(ggplot2::aes(x = industry_name.x, y = share, fill = geography_name.x)) +
ggplot2::geom_col(position = "dodge") +
ggplot2::coord_flip() +
ggplot2::theme_minimal()
