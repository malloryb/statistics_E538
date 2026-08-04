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
# The E-538 brand palette, specified by Mallory. The first two (cool sky /
# brick red) are essentially steelblue1 + firebrick, her preferred pairing and
# the strongest of several tested for colourblind separation (deltaE ~70 under
# deuteranopia, vs ~18-28 for Okabe-Ito orderings and ggplot2's default hue
# wheel). That matters because most figures in this book are binary
# comparisons, so the two most-used colours are also the best-separated ones.
# Figures that set their own scale_colour_manual()/scale_fill_manual() are
# unaffected; the options() below only replace ggplot2's default hue wheel.
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

# 4) Default colour for ungrouped geoms.
# The options() above only feed scale_colour_discrete()/scale_fill_discrete(),
# which ggplot only builds when colour/fill is mapped inside aes(). A plain
# geom_point()/geom_line() with no mapped colour never creates that scale, so
# it falls back to ggplot2's built-in black. update_geom_defaults() changes
# that built-in default instead, so ungrouped layers pick up the palette
# without every call needing an explicit colour=. Point and line are offset
# to different palette entries so a point+line combo (e.g. scatter + trend
# line) doesn't render as one indistinguishable colour; geom_smooth() already
# used "#b22222" for trend lines in several chapters, so line reuses that
# same slot. geom_hline()/geom_vline()/geom_abline()/geom_smooth() have their
# own separate default-aes entries and are unaffected by these two calls.
ggplot2::update_geom_defaults("point", list(colour = e538_plot_palette[3]))
ggplot2::update_geom_defaults("line",  list(colour = e538_plot_palette[2]))

# geom_histogram() is built on GeomBar, so this covers both. Default fill is
# "grey35" with no border, which is what produced the grey blobby look;
# switching to the palette's light blue with a black border keeps bars
# visually distinct from each other (crisper than a white/no border, and
# matches the black axis lines/text theme_classic already uses everywhere).
ggplot2::update_geom_defaults("bar", list(fill = e538_palette[1], colour = "black"))

# 5) Default theme.
# theme_set() changes what a bare ggplot() call renders with when a chunk
# adds no theme_*() of its own. A chunk that still calls theme_classic()
# explicitly (with or without base_size) overrides this, so this doesn't
# retroactively fix calls elsewhere in the book that pass no base_size.
ggplot2::theme_set(ggplot2::theme_classic(base_size = 14))
