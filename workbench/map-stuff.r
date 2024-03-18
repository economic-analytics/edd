# # Map Output --------------------------------------------------------------

#   # output$leafletmap <- leaflet::renderLeaflet({
#   #   # data <- filter(data_to_plot(),
#   #   #                dates$date == input$dates)
#   #   # boundaries <- get(input$geog_type, boundaries) # access geoms for input$geog_type
#   #   #
#   #   # mapdata <- dplyr::inner_join(boundaries,
#   #   #                              data,
#   #   #                              # by = setNames("geography", paste0(input$geog_type, "18cd"))
#   #   #                              by = setNames("geography", names(boundaries)[2])
#   #   #                              )
#   #   # pal <- colorNumeric("YlOrRd", domain = mapdata$data$value) # needs to be reactive
#   #   pal <- map_pal()
#   #
#   #   leaflet::leaflet() %>%
#   #     leaflet::addTiles() %>%
#   #     leaflet::addPolygons(data = map_data(),
#   #                          fillColor = ~pal(value),
#   #                          weight = 1,
#   #                          color = "Blue",
#   #                          label = map_data()$value)
#   # })

#   # map_data should be filtered by reactive values on all dimensions
#   # *INCLUDING* date but *EXCEPT* geography - all geog_levels from UI select
#   # [geog_type] should be included

#   output$map_date_select <- renderUI({
#     sliderInput(
#       inputId = "map_date_select",
#       label   = "Select date",
#       min     = min(data_to_plot()$dates$date),
#       max     = max(data_to_plot()$dates$date),
#       value   = max(data_to_plot()$dates$date)
#     )
#   })

#   map_pal <- reactive({
#     leaflet::colorNumeric("YlOrRd", domain = map_data()$value)
#   })




#   output$map_output <- renderUI({
#     radioButtons(
#       inputId = "geog_type",
#       label   = "Display data by:",
#       choices = names(boundaries),
#       inline  = TRUE
#     )
#     #          uiOutput("map_date_select"),
#     #          leaflet::leafletOutput("leafletmap")
#   })