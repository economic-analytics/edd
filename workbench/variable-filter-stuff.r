  # output$variable_filter <- renderUI({
  #   checkboxInput(inputId = "variable_filter",
  #                 label   = "Search only selected datasets?",
  #                 value   = TRUE
  #   )
  # })
  #
  # select_variable_choices <- reactive({
  #   req(edd_datasets, user_datasets())
  #   if (input$variable_filter) {
  #     source_object <- user_datasets()
  #   } else {
  #     source_object <- edd_datasets
  #   }
  #   lapply(source_object, function(ds) {
  #     as.list(ds$dimensions$variable$name)
  #   })
  # })

  # output$variable <- renderUI({
  #   req(edd_datasets, user_datasets())
  #   value <- isolate(input$variable)
  #   selectInput(inputId  = "variable",
  #               label    = "Select variable",
  #               # choices  = select_variable_choices(),
  #               choices = lapply(user_datasets(), function(ds) {
  #                 as.list(ds$dimensions$variable$name)
  #               }),
  #               selected = value,
  #               multiple = TRUE
  #   )
  # })