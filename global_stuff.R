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

# ============================================================================
# 6) Study-design cards.
# A consistent schematic for each chapter's running example, so students can
# see that e.g. "near vs far highway" and "three forest types" are the same
# structure with a different number of boxes. Organisational imagery, not
# decorative: every element carries information (levels, n, the unit of
# observation, the DV, the question). Five templates:
#   design_groups()      categorical levels          (also paired, dashed)
#   design_continuous()  continuous predictor
#   design_crossed()     two factors, fully crossed  (A x B = cells)
#   design_mixed()       continuous x categorical    (ANCOVA)
#   design_gof() / design_contingency()   count data (chi-square)
# All share a fixed grid so the IV/DV lines land in the same place every time.
# ============================================================================
# ---- fixed layout grid: every card puts every line in the same place --------
X0     <- 0.15   # left margin for all text
XSHAPE <- 2.35   # shapes start here; 0.15-2.2 reserved for the kind-label
XMAX   <- 10
Y_IV   <- 0.62
Y_KIND <- 0.05
Y_DV   <- -0.72
Y_Q    <- -1.00
LAB_SIZE <- 4.0                 # IV and DV carry identical weight

frame <- function(iv_label, dv_label, question, kind_word,
                  iv_prefix = "IV:  ", dv_prefix = "DV:  ") {
  list(
    annotate("text", x = X0, y = Y_IV, hjust = 0, label = paste0(iv_prefix, iv_label),
             size = LAB_SIZE, fontface = "bold", colour = "grey10"),
    annotate("text", x = X0, y = Y_KIND, hjust = 0, label = kind_word,
             size = 3.4, colour = "grey45"),
    annotate("text", x = X0, y = Y_DV, hjust = 0, label = paste0(dv_prefix, dv_label),
             size = LAB_SIZE, fontface = "bold", colour = "grey10"),
    annotate("text", x = X0, y = Y_Q, hjust = 0, label = question,
             size = 3.6, fontface = "italic", colour = "#b22222"),
    coord_cartesian(xlim = c(0, XMAX), ylim = c(-1.15, 0.8), expand = FALSE),
    theme_void()
  )
}

box_xs <- function(k, w) {
  gap <- 0.30
  total <- k * w + (k - 1) * gap
  start <- XSHAPE
  start + (seq_len(k) - 1) * (w + gap) + w / 2
}

# ---- TEMPLATE 1: categorical levels ---------------------------------------
design_groups <- function(iv, levels, n_each, unit, dv, question, kind = "Levels",
                        dashed = FALSE, note = NULL) {
  k <- length(levels); n_each <- rep_len(n_each, k)
  w <- min(2.35, (XMAX - XSHAPE - 0.25 - (k - 1) * 0.30) / k)
  d <- data.frame(x = box_xs(k, w), levels, n_each)
  ggplot(d) +
    geom_tile(aes(x = x, y = Y_KIND), width = w, height = 0.62,
              fill = NA, colour = "grey25", linewidth = 0.7,
              linetype = if (dashed) "22" else "solid") +
    geom_text(aes(x = x, y = Y_KIND + 0.11, label = levels),
              fontface = "bold", size = 3.8, colour = "grey5") +
    geom_text(aes(x = x, y = Y_KIND - 0.11, label = paste0("n = ", n_each, " ", unit)),
              size = 3.1, colour = "grey35") +
    (if (!is.null(note))
       annotate("text", x = mean(range(d$x)), y = Y_KIND - 0.44, label = note,
                size = 3.0, fontface = "italic", colour = "grey45")) +
    frame(iv, dv, question, kind)
}

# ---- TEMPLATE 2: continuous predictor -------------------------------------
design_continuous <- function(iv, low, high, n_label, dv, question) {
  xa <- XSHAPE + 0.15; xb <- XMAX - 0.35
  ggplot(data.frame(x = 1)) +
    annotate("segment", x = xa, xend = xb, y = Y_KIND, yend = Y_KIND,
             colour = "grey25", linewidth = 0.9,
             arrow = grid::arrow(length = grid::unit(0.20, "cm"), type = "closed")) +
    annotate("segment", x = c(xa, xb), xend = c(xa, xb),
             y = Y_KIND - 0.09, yend = Y_KIND + 0.09,
             colour = "grey25", linewidth = 0.7) +
    annotate("text", x = xa, y = Y_KIND - 0.22, hjust = 0, label = low,
             size = 3.1, colour = "grey35") +
    annotate("text", x = xb, y = Y_KIND - 0.22, hjust = 1, label = high,
             size = 3.1, colour = "grey35") +
    annotate("text", x = (xa + xb)/2, y = Y_KIND + 0.22, label = n_label,
             size = 3.1, colour = "grey35") +
    frame(iv, dv, question, "Continuous")
}

# ---- TEMPLATE 3: two predictors side by side (ANCOVA) ---------------------
design_mixed <- function(iv, low, high, n_label, factor_levels, dv, question, note) {
  # left block: categorical levels | right block: continuous gradient
  lx0 <- XSHAPE; lw <- 1.55; lgap <- 0.22
  k <- length(factor_levels)
  lxs <- lx0 + (seq_len(k) - 1) * (lw + lgap) + lw / 2
  lx1 <- max(lxs) + lw / 2
  cx  <- lx1 + 0.62                       # the "x" joining the two blocks
  ra  <- cx + 0.62; rb <- XMAX - 0.30

  ggplot(data.frame(x = 1)) +
    # --- left: categorical
    annotate("text", x = mean(lxs), y = Y_KIND + 0.40, label = "Categorical",
             size = 3.2, fontface = "bold", colour = "grey45") +
    annotate("tile", x = lxs, y = Y_KIND, width = lw, height = 0.42,
             fill = NA, colour = "grey25", linewidth = 0.7) +
    annotate("text", x = lxs, y = Y_KIND, label = factor_levels,
             fontface = "bold", size = 3.5, colour = "grey5") +
    # --- the interaction "x"
    annotate("text", x = cx, y = Y_KIND, label = "\u00d7", size = 6, colour = "grey35") +
    # --- right: continuous
    annotate("text", x = (ra + rb)/2, y = Y_KIND + 0.40, label = "Continuous",
             size = 3.2, fontface = "bold", colour = "grey45") +
    annotate("segment", x = ra, xend = rb, y = Y_KIND, yend = Y_KIND,
             colour = "grey25", linewidth = 0.9,
             arrow = grid::arrow(length = grid::unit(0.18, "cm"), type = "closed")) +
    annotate("segment", x = ra, xend = ra, y = Y_KIND - 0.09, yend = Y_KIND + 0.09,
             colour = "grey25", linewidth = 0.7) +
    annotate("text", x = ra, y = Y_KIND - 0.21, hjust = 0, label = low,
             size = 3.0, colour = "grey35") +
    annotate("text", x = rb, y = Y_KIND - 0.21, hjust = 1, label = high,
             size = 3.0, colour = "grey35") +
    annotate("text", x = (ra + rb)/2, y = Y_KIND - 0.40, label = note,
             size = 2.9, fontface = "italic", colour = "grey45") +
    annotate("text", x = mean(lxs), y = Y_KIND - 0.40, label = n_label,
             size = 3.0, colour = "grey35") +
    frame(iv, dv, question, "Two predictors")
}


# ---- TEMPLATE 3c: crossed factors, reading as arithmetic (A x B = cells) ----
# initials of each level, e.g. "No Pollution" -> "NP", "Pollution" -> "P"
abbrev <- function(x) vapply(strsplit(x, "\\s+"),
                             function(w) paste0(toupper(substr(w, 1, 1)), collapse = ""), "")

design_crossed <- function(iv, levels_a, levels_b, dv, question, note) {
  bw <- 1.02; gap <- 0.11
  ka <- length(levels_a); kb <- length(levels_b)
  ax <- XSHAPE + (seq_len(ka)-1)*(bw+gap) + bw/2
  cx <- max(ax) + bw/2 + 0.34
  bx <- cx + 0.34 + (seq_len(kb)-1)*(bw+gap) + bw/2
  ex <- max(bx) + bw/2 + 0.36                       # the "=" sign
  # mini grid: uniform gap in BOTH directions
  cellw <- 0.68; cellh <- 0.26; cgap <- 0.08
  gx0 <- ex + 0.36
  gxs <- gx0 + (seq_len(kb)-1)*(cellw+cgap) + cellw/2
  gys <- Y_KIND + ((ka-1)/2 - (seq_len(ka)-1)) * (cellh+cgap)
  cells <- expand.grid(row = seq_len(ka), col = seq_len(kb))
  cells$x <- gxs[cells$col]; cells$y <- gys[cells$row]
  cells$lab <- paste0(abbrev(levels_a)[cells$row], "\u00d7", abbrev(levels_b)[cells$col])

  ggplot(data.frame(x=1)) +
    annotate("text", x = mean(ax), y = Y_KIND+0.42, label = "Factor 1",
             size = 3.1, fontface="bold", colour="grey45") +
    annotate("tile", x = ax, y = Y_KIND, width = bw, height = 0.42,
             fill = NA, colour = "grey25", linewidth = 0.7) +
    annotate("text", x = ax, y = Y_KIND, label = levels_a, fontface="bold",
             size = 2.8, colour = "grey5") +
    annotate("text", x = cx, y = Y_KIND, label = "\u00d7", size = 5.5, colour="grey35") +
    annotate("text", x = mean(bx), y = Y_KIND+0.42, label = "Factor 2",
             size = 3.1, fontface="bold", colour="grey45") +
    annotate("tile", x = bx, y = Y_KIND, width = bw, height = 0.42,
             fill = NA, colour = "grey25", linewidth = 0.7) +
    annotate("text", x = bx, y = Y_KIND, label = levels_b, fontface="bold",
             size = 2.8, colour = "grey5") +
    annotate("text", x = ex, y = Y_KIND, label = "=", size = 5.5, colour="grey35") +
    annotate("text", x = mean(gxs), y = Y_KIND+0.42,
             label = paste0(ka*kb, " conditions"), size = 3.1, fontface="bold", colour="grey45") +
    annotate("tile", x = cells$x, y = cells$y, width = cellw, height = cellh,
             fill = NA, colour = "grey25", linewidth = 0.6) +
    annotate("text", x = cells$x, y = cells$y, label = cells$lab,
             size = 2.2, colour = "grey15") +
    annotate("text", x = mean(c(min(ax), max(gxs))), y = Y_KIND-0.44, label = note,
             size = 3.0, fontface="italic", colour="grey45") +
    frame(iv, dv, question, "Fully crossed")
}

# ---- TEMPLATE 4: chi-square goodness-of-fit (observed vs expected) ---------
design_gof <- function(var_label, cats, observed, expected_note, counted, question) {
  k <- length(cats); bw <- 1.35; gap <- 0.25
  xs <- XSHAPE + (seq_len(k)-1)*(bw+gap) + bw/2
  ggplot(data.frame(x=1)) +
    annotate("text", x = mean(xs), y = Y_KIND+0.44, label = "Observed counts",
             size = 3.1, fontface="bold", colour="grey45") +
    annotate("tile", x = xs, y = Y_KIND+0.10, width = bw, height = 0.40,
             fill = NA, colour = "grey25", linewidth = 0.7) +
    annotate("text", x = xs, y = Y_KIND+0.17, label = cats, size = 3.0, colour="grey35") +
    annotate("text", x = xs, y = Y_KIND+0.03, label = observed,
             fontface="bold", size = 3.4, colour="grey5") +
    annotate("text", x = mean(xs), y = Y_KIND-0.22, label = "compared against",
             size = 2.9, fontface="italic", colour="grey45") +
    annotate("tile", x = xs, y = Y_KIND-0.44, width = bw, height = 0.26,
             fill = NA, colour = "grey45", linewidth = 0.6, linetype = "22") +
    annotate("text", x = xs, y = Y_KIND-0.44, label = expected_note,
             size = 3.0, colour="grey35") +
    frame(var_label, counted, question, "One variable",
          iv_prefix = "Variable:  ", dv_prefix = "What's counted:  ")
}

# ---- TEMPLATE 5: chi-square independence (contingency of counts) -----------
design_contingency <- function(vars_label, rows, cols, counts, counted, question) {
  nr <- length(rows); nc <- length(cols)
  cw <- 1.35; ch <- 0.28
  x0 <- XSHAPE + 1.85
  xs <- x0 + (seq_len(nc)-1)*cw + cw/2
  ys <- Y_KIND + 0.22 - (seq_len(nr)-1)*ch
  ggplot(data.frame(x=1)) +
    annotate("text", x = xs, y = max(ys)+0.26, label = cols,
             size = 3.0, fontface="bold", colour="grey35") +
    annotate("text", x = x0-0.12, y = ys, hjust = 1, label = rows,
             size = 3.0, fontface="bold", colour="grey35") +
    annotate("tile", x = rep(xs, each=nr), y = rep(ys, times=nc),
             width = cw, height = ch, fill = NA, colour = "grey25", linewidth = 0.6) +
    annotate("text", x = rep(xs, each=nr), y = rep(ys, times=nc),
             label = as.character(counts), size = 3.2, colour="grey5") +
    annotate("text", x = mean(xs), y = min(ys)-0.30,
             label = "each cell is a count of sites", size = 2.9,
             fontface="italic", colour="grey45") +
    frame(vars_label, counted, question, "Two variables,\ncounts in cells",
          iv_prefix = "Variables:  ", dv_prefix = "What's counted:  ")
}

