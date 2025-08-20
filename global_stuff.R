#Don't create PDF companions during HTML builds
options(knitr.graphics.auto_pdf = FALSE)

knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  message = FALSE,
  warning = FALSE,
  out.width = '75%',
  echo = FALSE
)
