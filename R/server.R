server <- function(input, output, session) {

  # Bookmarking (persistent URLs) ----

  # Automatically bookmark every time an input changes
  observe({
    reactiveValuesToList(input)
    session$doBookmark()
  })

  # Update the query string
  onBookmarked(updateQueryString)

  # UI Rendering ----

  output$dataset <- renderUI({
    selectizeInput(
      inputId  = "dataset",
      label    = "Select dataset(s)",
      # only shows datasets for which a download date exists in edd_dict
      choices  = edd_dict$desc[
        !is.na(edd_dict$last_download)
      ],
      multiple = TRUE,
      options  = list(plugins = list("remove_button"))
    )
  })

  output$dimensions <- renderUI({
    dims_available <- names(user_datasets())[
      !grepl("dataset|dates|value", names(user_datasets()))
    ]
    dims_available <- stringr::str_remove(dims_available, "\\..*") |>
      unique()

    lapply(dims_available, function(i) {
      value <- isolate(input[[i]])
      selectizeInput(
        i,
        paste("Select", i),
        choices = user_datasets() |>
          dplyr::distinct(dplyr::across(paste0(i, ".name"))) |>
          dplyr::pull(as_vector = TRUE),
        selected = value,
        multiple = TRUE,
        options = list(plugins = list("remove_button"))
      )
    })
  })

  output$transformations <- renderUI({
    req(input$dates)
    selectInput(
      inputId = "transformations",
      label   = "Transform data series",
      choices = c(
        "None (data as published)"   = "none",
        "Index"                      = "index",
        "Nominal change on previous" = "nominal_change",
        "Percent change on previous" = "percent_change",
        "Cumulative change"          = "cumulative_change"
      )
    )
  })

  transformation_date_choices <- reactive({
    # allows selection only of those dates which are available for all of the
    # data currently displayed on the plot
    df <- filtered_datasets() |>
      dplyr::group_by(dates.date) |>
      dplyr::summarise(n = dplyr::n()) |>
      dplyr::filter(n == max(n))
    return(df$dates.date)
  })

  output$transformation_date <- renderUI({
    req(input$transformations)
    if (input$transformations == "index") {
      value <- isolate(input$transformation_date)
      selectInput(
        inputId  = "transformation_date",
        label    = "Select date to index to",
        choices  = transformation_date_choices(),
        selected = value
      )
    }
  })

  output$frequency <- renderUI({
    req(input$dataset)
    # frequencies <- unique(user_datasets()$dates.freq)
    frequencies <- user_datasets() |>
      dplyr::distinct(dates.freq) |>
      dplyr::pull(as_vector = TRUE)
    value <- isolate(input$frequency)
    checkboxGroupInput(
      inputId  = "frequency",
      label    = "Which frequencies?",
      choices  = frequencies,
      selected = c(value, frequencies[1]),
      inline   = TRUE
    )
  })

  output$dates <- renderUI({
    req(input$dataset)
    # dates1 <- unique(user_datasets()$dates.date)
    dates1 <- user_datasets() |>
      dplyr::distinct(dates.date) |>
      dplyr::pull(as_vector = TRUE)
    min <- min(dates1)
    max <- max(dates1)
    sliderInput(
      "dates",
      label = "Select time period",
      min = min,
      max = max,
      value = c(min, max)
    )
  })

  # new reactive to handle dimensions in the built df to avoid calculating twice
  # excludes dataset, dates and value as these will always exist in all datasets
  available_dimensions <- reactive({
    dims <- names(user_datasets())[
      !grepl("dataset|dates|value", names(user_datasets()))
    ]
    dims <- stringr::str_remove(dims, "\\..*") |> unique()

    # Generate observers on available_dimensions() for managing plot aesthetics
    lapply(dims, function(i) {
      observeEvent(input[[i]], {
        manage_plot_group(i)
      })
    })

    return(dims)
  })

  # GLOBAL VARIABLE
  plot_aesthetics <- c("Colour", "Facet", "Linetype", "Shape")

  output$plot_aes <- renderUI({
    req(available_dimensions())

    lapply(plot_aesthetics, function(aes) {
      value <- isolate(input[[aes]])
      selectizeInput(
        aes,
        aes,
        choices = c(
          "Dimension" = "",
          available_dimensions()
        ),
        selected = value,
        multiple = FALSE
      )
    })
  })

  output$y_axis_zero <- renderUI({
    checkboxInput("y_axis_zero", "Show zero on y-axis")
  })

  output$add_smoothing  <- renderUI({
    checkboxInput("add_smoothing", "Add smoothing")
  })

  output$download_plot <- downloadHandler(
    filename = function() {
      paste0("edd_plot_", Sys.Date(), ".png")
    },
    content = function(file) {
      ggplot2::ggsave(file)
    }
  )

  output$download_data <- downloadHandler(
    filename = function() {
      paste0("edd_data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      readr::write_csv(ggplot_data(), file)
    }
  )

  # Place Analysis ----

  output$place_geography <- renderUI({
    place_rgva <- retrieve_dataset("RGVA") |>
      dplyr::distinct(geography.name) |>
      dplyr::pull(as_vector = TRUE)

    selectizeInput(
      "place_geography",
      "Select geography",
      choices = place_rgva,
      selected = place_rgva[1],
      multiple = TRUE,
      options = list(plugins = list("remove_button"))
    )
  })

  output$place_date <- renderUI({
    place_dates <- retrieve_dataset("RGVA") |>
      dplyr::distinct(dates.date) |>
      dplyr::pull(as_vector = TRUE)

    selectInput(
      "place_date",
      "Select date",
      choices = place_dates,
      selected = max(place_dates)
    )
  })

  output$place_analysis_type <- renderUI({
    selectInput(
      "place_analysis_type",
      "Select analysis",
      choices = c(
        "GVA share",
        "GVA LQ"
      )
    )
  })

  output$place_plot <- renderPlot({
    rgvaShare  <- retrieve_dataset("RGVA") |>
      # latest year
      dplyr::filter(dates.date == input$place_date) |>
      # constant prices
      dplyr::filter(variable.code == "constant") |>
      # calculate industry share as share of total for the same geog
      dplyr::group_by(dates.date, geography.code) |>
      dplyr::collect() |>
      dplyr::mutate(share = value / value[industry.code == "Total"])

    if (input$place_analysis_type == "GVA share") {
      # industry share by GVA
      rgvaShare |>
        dplyr::filter(geography.name %in% input$place_geography) |>
        # filter for SIC2007 sections (single letter code)
        dplyr::filter(grepl("^[A-Z]{1} ", industry.code)) |>
        ggplot2::ggplot(ggplot2::aes(
          x = industry.name,
          y = share,
          fill = geography.name
        )) +
        ggplot2::geom_col(position = "dodge") +
        ggplot2::coord_flip() +
        ggplot2::theme_minimal() +
        ggplot2::labs(
          title = "Proportion of GVA by SIC2007 sector",
          subtitle = paste(
            paste(
              input$place_geography, collapse = ","
            ),
            "in",
            substr(unique(rgvaShare$dates.date), 1, 4)
          ),
          caption = "Source: ONS Regional GVA (balanced)",
          x = "SIC 2007 Sector",
          y = "Share of GVA",
          fill = NULL
        ) +
        ggplot2::theme(
          legend.position = "top",
          axis.text = ggplot2::element_text(size = 12),
          legend.text = ggplot2::element_text(size = 12)
        )
    } else if (input$place_analysis_type == "GVA LQ") {
      # location quotient by GVA
      rgvaShare |>
        # select geographies to display/compare
        dplyr::filter(geography.name %in% input$place_geography) |>
        # filter for SIC2007 sections (single letter code)
        dplyr::filter(grepl("^[A-Z]{1} ", industry.code)) |>
        dplyr::inner_join(
          rgvaShare |> dplyr::filter(geography.code == "UK"),
          by = names(rgvaShare)[grepl("dates|industry|variable", names(rgvaShare))]
        ) |>
        dplyr::mutate(lq = share.x / share.y) |>
        ggplot2::ggplot(ggplot2::aes(x = industry.name, y = lq, fill = lq > 1)) +
        ggplot2::geom_col() +
        ggplot2::geom_point(ggplot2::aes(y = share.x * 10), size = 3) +
        ggplot2::coord_flip() +
        ggplot2::geom_hline(yintercept = 1, colour = "red") +
        ggplot2::facet_wrap("geography.name.x") +
        ggplot2::theme_minimal() +
        ggplot2::theme(
          legend.position = "none",
          axis.text = ggplot2::element_text(size = 12),
          strip.text = ggplot2::element_text(size = 12)
        ) +
        ggplot2::labs(
          caption = "Source: ONS Regional GVA (balanced)",
          x = "SIC 2007 Sector",
          y = "Location Quotient (bars)",
          fill = NULL
        ) +
        ggplot2::scale_y_continuous(
          sec.axis = ggplot2::sec_axis(
            ~ . * 10,
            name = "Share of GVA (dots) (%)"
          )
        )
    }
  })

  output$data_catalogue <- DT::renderDT({
    show_all_variables()
  })

  # Reactive Objects ----

  # user_datasets() contains the datasets selected by the user
  # in input$dataset. These are returned as Arrow tables and
  # therefore any call to this will need to be followed by a
  # call to dplyr::collect() to bring data into R
  user_datasets <- reactive({
    ids <- edd_dict$id[edd_dict$desc %in% input$dataset]

    if (length(input$dataset) > 0) {
      out <- lapply(ids, function(dataset_id) {
        retrieve_dataset(dataset_id)
      })

      out <- do.call(arrow::concat_tables, out)

      return(out)
    }
  })

  # filtered_datasets() reads from Arrow table user_datasets()
  # and is then additionally filtered by the variable choices from
  # input$dataset(s), date filters from input$date, and any other
  # dimension filters from input$[dimension_name] and only the
  # data required to visualise is retrieved from remote source
  filtered_datasets <- reactive({
    req(user_datasets())
    out <- user_datasets()

    # filter by variable
    if (!is.null(input$variable)) {
      out <- out |>
        dplyr::filter(variable.name %in% input$variable)
    }

    # filter by date
    if (!is.null(input$dates)) {
      out <- out |>
        dplyr::filter(
          dates.date >= input$dates[1],
          dates.date <= input$dates[2]
        )
    }

    # filter by frequency
    if (!is.null(input$frequency)) {
      out <- out |>
        dplyr::filter(
          dates.freq %in% input$frequency
        )
    }

    dims <- isolate(available_dimensions())
    for (d in dims) {
      out <- out |>
        dplyr::filter(
          .data[[paste0(d, ".name")]] %in% input[[d]] |
            is.na(.data[[paste0(d, ".name")]])
        )
    }

    out <- dplyr::collect(out)

    return(out)
  })

  # ggplot_data() contains a potentially transformed filtered_datasets()
  # depending on whether any ts_transformations have been selected via
  # input$transformations
  ggplot_data <- reactive({
    filtered_datasets() |>
      ts_transformations()
  })

  ts_transformations <- function(df) {
    req(input$transformations)
    if (input$transformations == "none") {
      return(df)
    }

    if (input$transformations == "index") {
      req(input$transformation_date)
      return(
        ts_transform_df[[input$transformations]](df, input$transformation_date)
      )
    }

    return(ts_transform_df[[input$transformations]](df))
  }

  # Plot Logic ----

  manage_plot_group <- function(i) {
    if (length(input[[i]]) > 1) {
      # find first unselected input$aes_*
      for (aes in plot_aesthetics) {
        if (input[[aes]] == "") {
          updateSelectizeInput(
            session,
            aes,
            selected = i
          )
          break
        }

        if (input[[aes]] == i) {
          break
        }
      }

    } else {
      # find which input$aes_* contains it and remove it
      for (aes in plot_aesthetics) {
        if (input[[aes]] == i) {
          updateSelectizeInput(
            session,
            aes,
            selected = ""
          )
          break
        }
      }
    }
  }

  # Plot Output ----

  output$dataplot <- renderPlot({
    req(ggplot_data())
    if (nrow(ggplot_data()) < 10000 && nrow(ggplot_data()) > 0) {
      ggplot2::ggplot(
        ggplot_data(),
        ggplot2::aes_string(
          x        = "dates.date",
          y        = "value",
          colour   = {if (input$Colour == "") NULL else paste0(input$Colour, ".name")},
          linetype = {if (input$Linetype == "") NULL else paste0(input$Linetype, ".name")},
          shape    = {if (input$Shape == "") NULL else paste0(input$Shape, ".name")}
        )
      ) +
        ggplot2::geom_line(size = 1) +
        {if (input$Shape != "") ggplot2::geom_point(size = 3)} +
        {if (input$Facet != "") ggplot2::facet_wrap(paste0(input$Facet, ".name"), labeller = ggplot2::label_wrap_gen())} +
        {if (input$add_smoothing) ggplot2::geom_smooth()} +
        ggplot2::labs(
          x        = NULL,
          y        = plot_ylab(ggplot_data(), input),
          title    = "",
          subtitle = "",
          caption  = plot_caption(input$dataset),
          colour   = stringr::str_to_sentence(input$Colour),
          linetype = stringr::str_to_sentence(input$Linetype),
          shape    = stringr::str_to_sentence(input$Shape)
        ) +
        ggplot2::theme(
          panel.background   = ggplot2::element_blank(),
          panel.grid         = ggplot2::element_blank(),
          panel.grid.major.y = ggplot2::element_line(linetype = "dotted"),
          legend.position    = "top",
          axis.line.y.right  = NULL,
          axis.line          = ggplot2::element_line(),
          text               = ggplot2::element_text(size = 16)
        ) +
        {if (input$Colour == "") NULL else ggplot2::guides(colour = ggplot2::guide_legend(nrow = 2))} +
        {if (input$Linetype == "") NULL else ggplot2::guides(linetype = ggplot2::guide_legend(nrow = 2))} +
        {if (input$Shape == "") NULL else ggplot2::guides(shape = ggplot2::guide_legend(nrow = 2))} +
        {if (input$y_axis_zero) ggplot2::scale_y_continuous(labels = scales::label_comma(), limits = c(min(0, min(ggplot_data()$value)), NA)) else ggplot2::scale_y_continuous(labels = scales::label_comma())}
    }
  })

  # Table Output ----
  output$datatable <- DT::renderDT({
    ggplot_data()
  })

  # Dashboard ----
  output$dashboardUI <- renderUI({
    latest_indictors <- lapply("ECY2", function(x) {
      tempdata <- retrieve_dataset("MGDP") |>
        dplyr::filter(variable.code == x) |>
        # NB only filtering on variable name
        dplyr::collect()

      temp_value <- tempdata$value[tempdata$dates.date == max(tempdata$dates.date)]

      bslib::value_box(
        id = paste0("vb", x),
        style = 'background-color: #1BACAF!important;',
        title = "Monthly GDP",
        value = temp_value,
        showcase = build_mini_plots(x),
        full_screen = TRUE,
        em(unique(tempdata$variable.name), style = "font-size:0.8em"),
        p(
          paste(
            "Latest data is for",
            max(tempdata$dates.date)
          )
        )
      )
    })

    bslib::layout_column_wrap(
      width = 1 / 4,
      !!!latest_indictors
    )
  })

  build_mini_plots <- function(x) {
    sparkline <- plotly::plot_ly(
      retrieve_dataset("MGDP") |>
        dplyr::filter(variable.code == x) |>
        dplyr::collect()
    ) |>
      plotly::add_lines(
        x = ~dates.date, y = ~value,
        color = I("#FFFFFF"), span = I(1)
      ) |>
      plotly::layout(
        xaxis = list(visible = F, showgrid = F, title = ""),
        yaxis = list(visible = F, showgrid = F, title = ""),
        hovermode = "x",
        margin = list(t = 0, r = 0, l = 0, b = 0),
        font = list(color = "white"),
        paper_bgcolor = "transparent",
        plot_bgcolor = "transparent"
      ) |>
      plotly::config(displayModeBar = F) |>
      htmlwidgets::onRender(
        "function(el) {
          var ro = new ResizeObserver(function() {
            var visible = el.offsetHeight > 200;
            Plotly.relayout(el, {'xaxis.visible': visible});
          });
        ro.observe(el);
        }"
      )
    return(sparkline)
  }
}
