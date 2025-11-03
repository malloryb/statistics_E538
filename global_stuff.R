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
