# Make sure PDF companions are not created
options(knitr.graphics.auto_pdf = FALSE)

knitr::opts_chunk$set(
    # write assets to docs/<chapter>_files/figure-<dev>*
    fig.path = file.path(outdir, "figure-"),
    dev      = "png",
    fig.ext  = "png",
    dpi      = 120,
    # your existing defaults
    collapse = TRUE,
    comment  = "#>",
    message  = FALSE,
    warning  = FALSE,
    out.width= "75%",
    echo     = FALSE
  )
