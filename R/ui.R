ui <- function(request) {
  bslib::page_navbar(
    title = "EDD v0.0.0.9029 ALPHA",
    id = "navbar",
    window_title = "EDD: Economic Data Dashboard",

    bslib::nav_panel(
      id = "datatool",
      title = "Interactive data tool",

      # Application title
      shiny::titlePanel("EDD: Economic Data Dashboard"),

      # Sidebar UI
      bslib::page_sidebar(
        sidebar = bslib::sidebar(
          width = "25%",
          open = "always",
          bslib::navset_tab(
            id = "datatool_sidebar_tabs",
            bslib::nav_panel(
              title = "Select by dataset",
              uiOutput("dataset"),
              # uiOutput("variable_filter"),
              # uiOutput("variable"),
              uiOutput("dimensions"),
              uiOutput("dates"),
              uiOutput("frequency"),
              uiOutput("transformations"),
              uiOutput("transformation_date")
            )
          )
        ),

        # Main panel UI
        bslib::navset_tab(
          id = "datatool_mainpanel_tabs",
          bslib::nav_panel(
            title = "Chart",
            bslib::layout_sidebar(
              sidebar = bslib::sidebar(
                position = "right",
                title = "Chart options",
                uiOutput("plot_aes"),
                uiOutput("y_axis_zero"),
                uiOutput("add_smoothing"),
                shiny::downloadButton(
                  outputId = "download_plot",
                  label = "Download as PNG"
                )
              ),
              shiny::plotOutput("dataplot")
            )
          ),

          bslib::nav_panel(
            title = "Table",
            bslib::layout_sidebar(
              sidebar = bslib::sidebar(
                position = "right",
                title = "Table options",
                shiny::downloadButton(
                  outputId = "download_data",
                  label = "Download as CSV"
                )
              ),
              DT::DTOutput("datatable")
            )
          )
        )
      )
    ),

    tabPanel(
      id = "place_analysis",
      title = "Place Analysis",
      titlePanel("EDD: Place Analysis"),

      sidebarLayout(
        sidebarPanel(
          uiOutput("place_geography"),
          uiOutput("place_date"),
          uiOutput("place_analysis_type")
        ),
        mainPanel(
          plotOutput("place_plot", height = 600)
        )
      )
    ),

    tabPanel(
      id = "data_catalogue",
      title = "Data catalogue",
      DT::DTOutput("data_catalogue")
    ),

    tabPanel(
      id = "changelog",
      title = "Change log",
      htmltools::includeMarkdown("markdown/change-log.md")
    ),

    # Menu: about
    tabPanel(
      id = "about",
      title = "About",
      htmltools::includeMarkdown("markdown/about.md")
    )
  )
}
