plot_caption <- function(datasets) {

  caption_df <- edd_dict |>
    dplyr::filter(desc %in% datasets)

  if (length(datasets) == 1) {
    caption <- paste(caption_df$provider, caption_df$desc)
  }

  if (length(datasets) > 1) {
    if (length(unique(caption_df$provider)) == 1) {
      caption <- paste(caption_df$provider,
                       paste(caption_df$desc, collapse = ", "))
    }
  }

  return(paste0("Source: ", caption, "\nPowered by EDD"))
}

plot_ylab <- function(ggplot_data, input) {
  if (!exists("ggplot_data$variable$unit")) {
    ylab <- "Value"
  } else {
    if (input$transformations == "none") {
      ylab <- ggplot_data$variable$unit
    } else {
      ylab <- paste0(input$transformations, "(base period = ", input$transformation_date, ")")
    }
  }

  return(ylab)
}
