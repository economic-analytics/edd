x <- data.frame(a = as.Date(paste0("2000-", 1:12, "-01")),
                b = 1:12,
                c = as.Date(paste0("2000-", c(1, 4, 7, 10), "-01")),
                d = c(2, 4, 6, 8))

ggplot2::ggplot(x) +
  ggplot2::geom_line(ggplot2::aes(x = a, y = b)) +
  ggplot2::geom_col(ggplot2::aes(x = c, y = d))
