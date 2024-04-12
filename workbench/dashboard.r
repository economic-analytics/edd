# dashboard

dashboard.variable.codes <- c(
  GDP = "IHYR",
  `GDP per capita` = "N3Y8",
  # `GDP per hour worked` = "",
  CPI = "D7G7",
  `Employment rate (16-64)` = "LF24",
  `Unemployment rate (16-64)` = "LF2Q",
  `Economic inactivity rate (16-64)` = "LF2S",
  `Self-employed` = "MGRQ",
  `Retail sales (volume)` = "J5EK"
)

# retrieve data
dashboard.data <- edd_datasets |>
  dplyr::filter(variable.code %in% dashboard.variable.codes) |>
  dplyr::collect()

test <- lapply(dashboard.variable.codes, function(x) {
  data <- dashboard.data |>
    dplyr::filter(
      variable.code == x,
      dates.date > "2023-01-01"
    ) |>
    dplyr::collect() |>
    dplyr::filter(
      dates.date == max(dates.date)
    )
  
  bslib::value_box(
    title = x,
    value = unique(data$value)
  )
})

bslib::layout_column_wrap(test, width = 1/2)

test[[1]]



# server ----


  # Dashboard ----

  output$main_dashboard <- renderUI({
    dashboard.variable.codes <- c(
      GDP = "IHYR",
      `GDP per capita` = "N3Y8",
      # `GDP per hour worked` = "",
      CPI = "D7G7",
      `Employment rate (16-64)` = "LF24",
      `Unemployment rate (16-64)` = "LF2Q",
      `Economic inactivity rate (16-64)` = "LF2S",
      `Self-employed` = "MGRQ",
      `Retail sales (volume)` = "J5EK"
    )

    dashboard.data <- edd_datasets |>
      dplyr::filter(variable.code %in% dashboard.variable.codes) |>
      dplyr::collect()

    test <- lapply(seq_along(dashboard.variable.codes), function(x) {
      data <- dashboard.data |>
        dplyr::filter(
          variable.code == dashboard.variable.codes[x],
          dates.date > "2020-01-01"
        ) |>
        dplyr::collect() |>
        dplyr::filter(
          dates.date == max(dates.date)
        )

      bslib::value_box(
        title = unique(data$variable.name), #names(dashboard.variable.codes[x]),
        value = unique(data$value)
      )
    })
    
    bslib::layout_column_wrap(!!!test, width = 1/4)

    # do.call(
    #   bslib::layout_column_wrap,
    #   list(width = 1/2, test[])
    # )
  })

# ui ----


    tabPanel(
      id = "dashboard",
      title = "Dashboard",
      uiOutput("main_dashboard")
    )