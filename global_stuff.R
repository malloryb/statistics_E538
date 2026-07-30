knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  message = FALSE,
  warning = FALSE,
  out.width = '75%',
  echo = FALSE
)

suppressPackageStartupMessages({
  library(knitr)
  library(kableExtra)
})

knitr::opts_knit$set(allow_html = TRUE)  # allow HTML in PDF

# 1) Mask kable() so it auto-chooses format per target
kable <- function(x, format = NULL, ...) {
  if (knitr::is_latex_output()) format <- "latex"
  else if (is.null(format)) format <- "html"
  knitr::kable(x, format = format, ...)
}

# 2) Make scroll_box() a no-op in PDF
scroll_box <- function(x, ...) {
  if (knitr::is_latex_output()) return(x)
  kableExtra::scroll_box(x, ...)
}

if (knitr::is_latex_output()) {
  options(knitr.table.format = "latex")
} else {
  options(knitr.table.format = "html")
}

# 3) Book-wide default colour palette.
# Okabe-Ito: the standard colourblind-safe qualitative palette. Several chapters
# (Ch6, Ch7) already use these exact hex codes, so this makes the rest of the book
# match rather than introducing a new scheme. Figures that set their own
# scale_colour_manual()/scale_fill_manual() are unaffected; this only replaces
# ggplot2's default hue wheel, which is what made the multi-panel simulation
# figures look garish.
# The brand palette, exactly as specified.
e538_palette <- c(
  "#63b8ff",  # cool sky
  "#b22222",  # brick red
  "#1446a0",  # cobalt blue
  "#f5d547",  # royal gold
  "#ebebd3"   # beige
)

# Plotting variant. Identical to e538_palette except beige is darkened.
# Beige sits at Lab L=92 against white's L=100 (deltaE ~14), so as a point or
# line colour on a white panel it is close to invisible. The darkened version
# (#ACAC86, deltaE ~37) stays in the same hue family but is legible as data.
# Use e538_palette for fills/accents where a light tone is wanted;
# this one is the ggplot default for mapped data.
e538_plot_palette <- c(e538_palette[1:4], "#ACAC86")

options(
  ggplot2.discrete.colour = e538_palette,
  ggplot2.discrete.fill   = e538_palette
)
