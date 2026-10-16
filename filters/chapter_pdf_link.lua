-- Adds a "Download this chapter (PDF)" button under the title of each numbered
-- chapter page. The PDFs are built by scripts/build_chapter_pdfs.py into docs/pdf/.
function Pandoc(doc)
  if not quarto.doc.is_format("html") then
    return doc
  end
  local stem = pandoc.path.filename(quarto.doc.input_file):match("^(%d%d%-.+)%.qmd$")
  if not stem then
    return doc
  end
  local button = pandoc.RawBlock("html", string.format(
    '<p class="chapter-pdf-link"><a class="btn btn-outline-primary btn-sm" href="pdf/%s.pdf" download>' ..
    '<i class="bi bi-file-earmark-pdf" aria-hidden="true"></i> Download this chapter (PDF)</a></p>', stem))
  doc.blocks:insert(1, button)
  return doc
end
