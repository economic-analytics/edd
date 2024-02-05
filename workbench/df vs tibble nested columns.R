df <- data.frame(dates = data.frame(date = as.Date("2022-11-22"),
                                    freq = "a"),
                 geography = data.frame(code = "E02",
                                        name = "MSOA"),
                 industry = data.frame(code = "A",
                                       name = "Agriculture"),
                 variable = data.frame(code = "A1",
                                       name = "GVA CVM"),
                 value = 3.5)


tb <- tibble::tibble(dates = tibble::tibble(date = as.Date("2022-11-22"),
                                            freq = "a"),
                     geography = tibble::tibble(code = "E02",
                                                name = "MSOA"),
                     industry = tibble::tibble(code = "A",
                                               name = "Agriculture"),
                     variable = tibble::tibble(code = "A1",
                                               name = "GVA CVM"),
                     value = 3.5)

df_as_tb <- tibble::as_tibble(df)


dates = data.frame(date = as.Date("2022-11-22"),
                   freq = "a")
geography = data.frame(code = "E02",
                       name = "MSOA")
industry = data.frame(code = "A",
                      name = "Agriculture")
variable = data.frame(code = "A1",
                      name = "GVA CVM")
value = 3.5


cols <- c("dates", "geography")

tibble::tibble(tb["dates"],
               tb["geography"])


tb_from_dfs <- tibble::tibble(dates = dates,
                              geography = geography)


tb1$df <- tibble::tibble(x = 1:5)

