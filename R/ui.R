ui <- function(request) {
  navbarPage(
    title = "EDD v0.0.0.9029 ALPHA",
    id = "navbar",
    windowTitle = "EDD: Economic Data Dashboard",

    tabPanel(
      id = "datatool",
      title = "Interactive data tool",

      # Application title
      titlePanel("EDD: Economic Data Dashboard"),

      # Sidebar UI
      sidebarLayout(
        sidebarPanel(
          tabsetPanel(
            id = "datatool_sidebar_tabs",
            tabPanel(
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
        mainPanel(
          tabsetPanel(
            id = "datatool_mainpanel_tabs",
            tabPanel(
              title = "Chart",
              sidebarLayout(
                sidebarPanel(
                  p(strong("Chart options")),
                  tabsetPanel(
                    tabPanel("Plot aesthetics",
                             uiOutput("plot_aes"),
                             uiOutput("y_axis_zero"),
                             uiOutput("add_smoothing")
                    )
                  )
                ),
                mainPanel(
                  plotOutput("dataplot"),
                  downloadButton("download_plot",
                                 label = "Download as PNG")
                ),
                position = "right"
              )
              # uiOutput("plot_group"),


              # uiOutput("summarise"),

            ),

            tabPanel(
              title = "Table",
              DT::DTOutput("datatable"),
              downloadButton("download_data",
                             label = "Download as CSV")
            )
            # ,
            #
            # tabPanel(title = "Map",
            #          uiOutput("map_output"),
            #          uiOutput("map_date_select"),
            #          leaflet::leafletOutput("leafletmap")
            # )
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
