ui <- navbarPage(
  title = "FEDO v0.0.0.9000 ALPHA",
  id = "navbar",
  windowTitle = "FEDO: Future Economies Data Observatory",

  tabPanel(
    id = "datatool",
    title = "Interactive data tool",

    # Application title
    titlePanel("Future Economies Data Observatory"),

    # Sidebar UI
    sidebarLayout(
      sidebarPanel(
        tabsetPanel(id = "datatool_sidebar_tabs",
                    type = "pills",

                    tabPanel(title = "Select by dataset",
                             uiOutput("dataset"),
                             uiOutput("variable_filter"),
                             uiOutput("variable"),
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
        tabsetPanel(id = "datatool_mainpanel_tabs",
                    type = "pills",

                    tabPanel(title = "Chart",
                             uiOutput("plot_group"),
                             uiOutput("summarise"),
                             plotOutput("dataplot"),
                             downloadButton("download_plot",
                                            label = "Download as PNG")
                    ),

                    tabPanel(title = "Table",
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

  # Menu: about
  tabPanel(
    id = "about",
    title = "About FEDO",
    h2("About FEDO"),
    p("FEDO, the Future Economies Data Observatory, is a tool currently under development by Future Economies Analytics (FEA), a dedicated economic data and analytics unit housed within Future Economies University Centre for Research and Knowledge Exchange at Manchester Metropolitan University."),
    p("FEA has a remit to make economic data more useful, particularly at a sub-regional level, to support better analysis and policymaking in local areas."),
    p("FEDO will, in its first beta release (v0.0.1 expected Q4 2021), provide interactive access to most ONS datasets, including small area estimates, Land Registry housing transacation data, all NOMIS datasets and Companies House data for all active companies in the UK."),
    p("Later, FEDO will provide an API to access all data across multiple sources, providing a repository of small-geography economic data in a structured, linked format, with ISO8601 date formats and standard ONS geography codes to support easier access to cleaned and cubed data from multiple sources."),
    p("The development plan includes both imputation of all economic data to a small-area level (not less than MSOA) and a quarterly-updated forecasting model for all economies across the UK. Both of these will be on a commercial subscription basis."),
    p("If you're interested in its development, more information is available on its Github page at github.com/FutureEconomiesAnalytics/fedo."),
    p("For more information, please contact Christian Spence, Head of Economic Analytics, at c.spence@mmu.ac.uk.")
  ),

  tabPanel(
    id = "admin",
    title = "Admin",
    actionButton(inputId = "update_ons",
                 label   = "Update ONS datasets")
  )
)
