t <- tibble::tibble(
  dates = tibble::tibble(
    date = as.Date("2024-01-01"),
    freq = "m"
  ),
  variable = "GDP",
  value = 100
)

arrow::write_parquet(t, "workbench/t.parquet")

t1 <- arrow::read_parquet("workbench/t.parquet")

str(t1)

v <- tibble::tibble(
  code = "GDP",
  name = "Gross Domestic Product"
)

eddobj <- list(
  data = t,
  variable = v
)

str(eddobj)

eddobjparquet <- arrow::write_parquet(eddobj, "workbench/eddobj.parquet")

