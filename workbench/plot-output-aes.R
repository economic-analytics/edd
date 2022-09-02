library(shiny)

ui <- basicPage(
  selectInput("var",   "var",   choices = c("var1", "var2", "var3"), multiple = FALSE),
  selectInput("ind",   "ind",   choices = c("ind1", "ind2", "ind3"), multiple = TRUE),
  selectInput("geo",   "geo",   choices = c("geo1", "geo2", "geo3"), multiple = TRUE),
  selectInput("odd",   "odd",   choices = c("odd1", "odd2", "odd3"), multiple = TRUE),
  selectInput("group", "group", choices = c("var",  "ind",  "geo"),  multiple = TRUE)
)

server <- function(input, output, session){

  # this needs to capture the dimensions of the data set available for aes()
  inputs <- isolate(names(input)[!names(input) %in% c("group", "odd")])

  # This adds or removes dimensions from the input$plot_group to automatically
  # control aesthetics on the plot
  manage_plot_group <- function(i) {
    if (length(input[[i]]) > 1) {
      updateSelectInput(session,
                        inputId  = "group",
                        selected = c(input$group, i)
      )
    } else {
      updateSelectInput(session,
                        inputId  = "group",
                        selected = if (length(input$group) > 1) input$group[!input$group %in% i]
      )
    }
  }

  # Generate observers on the dimensions available
  lapply(inputs, function(i) {
    observeEvent(input[[i]], {
      print(input[[i]]) # testing only
      print(inputs) # testing only
      manage_plot_group(i)
      print(paste("Length of group is", length(input$group)))
    },
    ignoreNULL = FALSE,
    ignoreInit = TRUE)
  })
} # end of server function

shinyApp(ui, server)

  # observeEvent(input[[inputs[[1]]]], print("active"))



    # dim_inputs <- reactiveValues(input$var, input$ind, input$geo)
  # observeEvent(reactiveValuesToList(dim_inputs()),
  #              {
  #                for (i in seq_along(inputs)) {
  #                  if (length(input[[inputs[[i]]]]) > 1) {
  #                    print(paste(inputs[[i]], "greater than length 1"))
  #                    updateSelectInput(session, "group", selected = c(input$group, inputs[[i]]))
  #                  } else {
  #                    print(paste(inputs[[i]], "has length 1 or less"))
  #                    updateSelectInput(session, "group", selected = input$group[!input$group %in% inputs[[i]]])
  #                  }
  #                }
  #                print("\n")
  #              }
  #              )

  # listeners <- list()
  # for (i in seq_along(inputs)) {
  #   listeners[[i]] <- observeEvent(input[[inputs[[i]]]],
  #                                  if (length(input[[inputs[[i]]]]) > 1) {
  #                                    print(paste(inputs[[i]], "> 1"))
  #                                    updateSelectInput(session, "group", selected = c(input$group, inputs[[i]]))
  #                                  } else {
  #                                    print(paste(inputs[[i]], "<= 1"))
  #                                    updateSelectInput(session, "group", selected = input$group[input$group != inputs[[i]]])
  #                                  })
  # }



