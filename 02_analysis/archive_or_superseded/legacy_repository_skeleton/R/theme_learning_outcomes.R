learning_colours <- list(
  background = "#F7F5F0",
  text = "#17242D",
  muted_text = "#59636A",
  focus = "#315D8A",
  context = "#C3C7C9",
  context_dark = "#8B9298",
  grid = "#D8D8D3",
  warning = "#984F3F",
  ses_fill = c("#EBC45A", "#82A85B", "#5EA6A7", "#4C77A8", "#6B5A8E"),
  ses_line = c("#9A6D00", "#587A32", "#2C807F", "#4C77A8", "#6A4C93")
)

theme_learning_outcomes <- function(base_family = "Aptos", base_size = 16) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Install ggplot2 to use theme_learning_outcomes().")
  }

  ggplot2::theme_minimal(base_family = base_family, base_size = base_size) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = learning_colours$background, colour = NA),
      panel.background = ggplot2::element_rect(fill = learning_colours$background, colour = NA),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = learning_colours$grid, linewidth = 0.3),
      axis.title = ggplot2::element_text(colour = learning_colours$muted_text),
      axis.text = ggplot2::element_text(colour = learning_colours$text),
      plot.title = ggplot2::element_text(colour = learning_colours$text, face = "bold"),
      plot.subtitle = ggplot2::element_text(colour = learning_colours$muted_text),
      plot.caption = ggplot2::element_text(colour = learning_colours$muted_text, hjust = 0),
      legend.position = "none"
    )
}
