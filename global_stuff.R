# Make sure PDF companions are not created
options(knitr.graphics.auto_pdf = FALSE)

# Force figures for any chapter to be written under docs/<chapter>_files/...
local({
  # name of the current input without extension, e.g., "01-Science_Data"
  bn <- tools::file_path_sans_ext(basename(knitr::current_input()))
  # target asset folder inside docs
  outdir <- file.path("docs", paste0(bn, "_files"))
  # ensure subfolders exist (knitr will append 'figure-html' or 'figure-pdf')
  dir.create(file.path(outdir, "figure-html"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(outdir, "figure-pdf"),  recursive = TRUE, showWarnings = FALSE)

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
})
