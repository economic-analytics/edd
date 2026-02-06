mpr_path <- "~/Data/Bank of England/mpr-february-2025-charts-slides-and-data/Projections Databank - February 2026 MPR.xlsx"

# get sheet names
sheets <- readxl::excel_sheets(mpr_path)

# for now, we're ignoring conditioning assumptions (>=38)
# as they're in a separate format.

# Get sheet names which begin with a 1/2 digit number

data_sheets <- sheets[grepl("^[0-9]{1,2}", sheets)][1:37] # ignoring conditioning assumptions as above

# Extract metadata

# metadata is stored in cells A1:A3

metadata <- lapply(data_sheets, function(sht) {
  df <- readxl::read_excel(
    mpr_path,
    sheet = sht,
    range = "A1:A3",
    col_names = FALSE
  )
  out <- list(
    title = df[1, 1, drop = TRUE],
    variable.unit = df[2, 1, drop = TRUE],
    subtitle = df[3, 1, drop = TRUE]
  )
})

names(metadata) <- sapply(metadata, \(x) x$title)

# bring all these into a list
i = 1
data <- lapply(data_sheets, function(sht) {
  df <- readxl::read_excel(mpr_path, sheet = sht, skip = 4) |>
    tidyr::pivot_longer(-1, names_to = "date", values_drop_na = TRUE) |>
    dplyr::mutate(variable.name = sapply(metadata, \(x) x$title)[i]) |>
    dplyr::mutate(date_text_to_df(date)) |>
    dplyr::mutate(variable.code = variable.name) |>
    dplyr::mutate(dataset = "BOE_MPR") |>
    dplyr::rename(forecast.code = `Date of publication`) |> 
    dplyr::mutate(forecast.code = as.character(as.Date(forecast.code))) |> 
    dplyr::mutate(forecast.name = format(as.Date(forecast.code), "%B %Y")) |> 
    dplyr::select(
      dataset,
      dates.date = date,
      dates.freq = freq,
      variable.code,
      variable.name,
      forecast.code,
      forecast.name,
      value
    )
  i <<- i + 1
  return(df)
}) |>
  setNames(sapply(metadata, \(x) x$title)) |> 
  dplyr::bind_rows()
