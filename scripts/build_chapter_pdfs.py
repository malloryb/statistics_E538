#!/usr/bin/env python3
"""Build one standalone PDF per chapter, for the "Download this chapter (PDF)" links.

Usage (from the repo root, after rendering the HTML site so docs/ is current):
    LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 python3 scripts/build_chapter_pdfs.py 07-Nonparametric.qmd [more.qmd ...]
    LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 python3 scripts/build_chapter_pdfs.py --all
Options:
    --out DIR   where to write the PDFs (default docs/pdf)

Each chapter is copied into a temporary standalone Quarto project (not the book),
so it renders on its own. Cross-references to figures, tables and sections in
OTHER chapters cannot resolve in a standalone PDF; they are replaced with the
text the HTML site shows for them (e.g. "Figure 6.5"), read from docs/<chapter>.html.
The PDF carries the render date and the URL of the live version on every page.
"""
import datetime
import html
import os
import re
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = "https://malloryb.github.io/statistics_E538/"
BOOK = "Statistics for Environmental Science"
CHAPTERS = ["01-Data_Description.qmd", "02-Correlation.qmd", "03-SamplesPopulations.qmd",
            "04-Foundation_Inference.qmd", "05-Hypothesis_Testing.qmd", "06-ttests.qmd",
            "07-Nonparametric.qmd", "08-ANOVA.qmd", "09-Regression.qmd",
            "10-FactorialANOVA.qmd", "11-ANCOVA.qmd"]
SHARED = ["global_stuff.R", "StatisticsTextbook.bib", "imgs", "data"]


def xref_text(stem):
    """Map each cross-reference id to the text the HTML site shows for it."""
    path = os.path.join(REPO, "docs", stem + ".html")
    out = {}
    if not os.path.exists(path):
        return out
    page = open(path, encoding="utf-8").read()
    for m in re.finditer(r'<a href="([^"#]*)#([^"]+)" class="quarto-xref">(.*?)</a>', page, re.S):
        target_file, ref, text = m.groups()
        text = html.unescape(re.sub(r"<[^>]+>", "", text)).replace("\xa0", " ").strip()
        out[ref] = (target_file, text)
    return out


def prepare(src, chap_no, today):
    text = open(os.path.join(REPO, src), encoding="utf-8").read()
    stem = src[:-4]
    # Drop the book YAML front matter; this file gets its own.
    text = re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S)
    # The chapter's level-1 heading becomes the document title.
    # (skip fenced code, where "# " starts an R comment)
    lines = text.split("\n"); in_code = False; title = None
    for i, line in enumerate(lines):
        if line.startswith("```"):
            in_code = not in_code
        elif not in_code and line.startswith("# "):
            title = re.sub(r"\s*\{[^}]*\}\s*$", "", line[2:]).strip()
            del lines[i]
            break
    # Math or emphasis in a heading puts a Formula or Em tag inside the table of
    # contents, which fails PDF/UA-2. Single italic letters ($t$, $H_0$) look the
    # same set as italic text.
    in_code = False
    for i, line in enumerate(lines):
        if line.startswith("```"):
            in_code = not in_code
        elif not in_code and re.match(r"#{1,6} ", line):
            # \textit changes the font without adding an Em tag (also not allowed in the TOC).
            # \textsubscript adds a Span tag (not allowed either), so lower the digit by hand.
            line = re.sub(r"\$([A-Za-z])_(\w)\$", r"\\textit{\1}\\raisebox{-0.4ex}{\\footnotesize \2}", line)
            line = re.sub(r"\$([A-Za-z])\$", r"\\textit{\1}", line)
            lines[i] = re.sub(r"(?<!\*)\*([^*\s][^*]*)\*(?!\*)", r"\\textit{\1}", line)
    text = "\n".join(lines)
    # LaTeX cannot place a GIF. Chunks that include one directly (no PDF still in the
    # chapter) get the GIF's final frame, written into the work dir by build().
    gifs = []
    def still(m):
        chunk = m.group(0)
        g = re.search(r'include_graphics\((?:path\s*=\s*)?"(imgs/gifs/([\w-]+)\.gif)"\)', chunk)
        if not g:
            return chunk
        gifs.append(g.group(1))
        chunk = chunk.replace(g.group(0), f'include_graphics("gifstill_{g.group(2)}.png")')
        chunk = re.sub(r'(#\|\s*fig-alt:\s*["\'])Animation\.', r"\1Final frame of an animation.", chunk)
        return re.sub(r"(#\|\s*fig-cap:\s*)(['\"])(.*)\2\s*$",
                      lambda c: f"{c.group(1)}{c.group(2)}{c.group(3)} (Final frame. The animated version is in the web edition of this book.){c.group(2)}",
                      chunk, count=1, flags=re.M)
    text = re.sub(r"```\{r[^\n]*\n.*?\n```", still, text, flags=re.S)
    # A straight apostrophe in fig-alt reaches the PDF's alt text as "\textquotesingle".
    text = re.sub(r"(fig-alt[:=].*)", lambda m: m.group(1).replace("'", "’"), text)
    # Plain Markdown tables print cleanly in the PDF; raw LaTeX kable tables with
    # captions do not. Chapters that style tables with kableExtra keep LaTeX.
    if not re.search(r"kable_styling|column_spec|row_spec|add_header_above", text):
        text = text.replace('source("global_stuff.R")',
                            'source("global_stuff.R")\noptions(knitr.table.format = "pipe")\n'
                            'kable <- function(x, format = NULL, ...) knitr::kable(x, format = "pipe", ...)', 1)
    # References to labels defined in other chapters: use the site's text for them.
    local = set(re.findall(r"#\|\s*label:\s*([\w.-]+)", text)) | set(re.findall(r"\{#([\w.-]+)", text))
    shown = xref_text(stem)
    def fix(m):
        ref = m.group(1).rstrip(".")
        trail = m.group(1)[len(ref):]
        if ref in local:
            return m.group(0)
        target, txt = shown.get(ref, ("", None))
        if txt:
            return txt + trail
        return "the companion website" + trail
    text = re.sub(r"(?<![\w@])@((?:fig|tbl|sec|eq)-[\w.-]+)", fix, text)
    date_long = today.strftime("%B %-d, %Y")
    url = SITE + stem + ".html"
    front = f'''---
title: "Chapter {chap_no}: {title}"
subtitle: "{BOOK}"
author: "Mallory Barnes"
date: today
date-format: "[Rendered] MMMM D, YYYY"
shift-heading-level-by: -1
format:
  pdf:
    documentclass: scrartcl
    pdf-standard: ua-2      # tagged, screen-reader accessible PDF
    geometry: "margin=1in"
    toc: true
    toc-depth: 2
    number-sections: false
    fig-format: png
    fig-dpi: 200
    colorlinks: true
    include-in-header:
      text: |
        % Strikethroughs in math (Ch2 shows a factor cancelling in Pearson's r).
        \\usepackage{{cancel}}
        % The text font has no glyph for these; a missing glyph fails PDF/UA-2.
        \\usepackage{{newunicodechar}}
        \\newunicodechar{{≈}}{{\\ensuremath{{\\approx}}}}
        \\newunicodechar{{≤}}{{\\ensuremath{{\\leq}}}}
        \\newunicodechar{{≥}}{{\\ensuremath{{\\geq}}}}
        \\newunicodechar{{≠}}{{\\ensuremath{{\\neq}}}}
        \\newunicodechar{{μ}}{{\\ensuremath{{\\mu}}}}
        \\newunicodechar{{σ}}{{\\ensuremath{{\\sigma}}}}
        \\newunicodechar{{θ}}{{\\ensuremath{{\\theta}}}}
        \\newunicodechar{{χ}}{{\\ensuremath{{\\chi}}}}
        \\newunicodechar{{☐}}{{\\ensuremath{{\\square}}}}
        \\newunicodechar{{☑}}{{\\ensuremath{{\\boxtimes}}}}
        \\usepackage{{fancyhdr}}
        \\pagestyle{{fancy}}
        \\fancyhf{{}}
        \\renewcommand{{\\headrulewidth}}{{0pt}}
        \\fancyhead[R]{{\\footnotesize \\thepage}}
        \\fancyfoot[C]{{\\footnotesize Chapter {chap_no}, rendered {date_long}. Latest version: \\url{{{url}}}}}
        \\fancypagestyle{{plain}}{{\\fancyhf{{}}\\fancyhead[R]{{\\footnotesize \\thepage}}\\fancyfoot[C]{{\\footnotesize Chapter {chap_no}, rendered {date_long}. Latest version: \\url{{{url}}}}}\\renewcommand{{\\headrulewidth}}{{0pt}}}}
    include-before-body:
      text: |
        \\noindent\\small This PDF was rendered on {date_long}. The book is updated during the semester; the latest version of this chapter is at \\url{{{url}}}.\\par
        \\noindent\\small \\emph{{{BOOK}}} $\\cdot$ CC BY-SA 4.0 $\\cdot$ Credits and license: \\url{{{SITE}}}\\par\\medskip
bibliography: StatisticsTextbook.bib
execute:
  echo: false
  warning: false
  message: false
---

'''
    return stem, front + text, gifs


def build(src, outdir, today):
    chap_no = int(src.split("-")[0])
    stem, doc, gifs = prepare(src, chap_no, today)
    work = tempfile.mkdtemp(prefix="chpdf_")
    try:
        for item in SHARED:
            p = os.path.join(REPO, item)
            if os.path.exists(p):
                os.symlink(p, os.path.join(work, item))
        for g in gifs:
            im = Image.open(os.path.join(REPO, g))
            im.seek(im.n_frames - 1)
            im.convert("RGB").save(os.path.join(work, "gifstill_" + os.path.basename(g)[:-4] + ".png"))
        open(os.path.join(work, "_quarto.yml"), "w").write("project:\n  type: default\n")
        open(os.path.join(work, stem + ".qmd"), "w", encoding="utf-8").write(doc)
        r = subprocess.run(["quarto", "render", stem + ".qmd", "--to", "pdf"], cwd=work,
                           capture_output=True, text=True)
        if r.returncode != 0:
            sys.stderr.write(r.stdout[-3000:] + r.stderr[-3000:])
            raise SystemExit(f"FAILED: {src} (work dir kept: {work})")
        os.makedirs(outdir, exist_ok=True)
        shutil.copy(os.path.join(work, stem + ".pdf"), os.path.join(outdir, stem + ".pdf"))
        warn = [l for l in (r.stdout + r.stderr).splitlines() if "WARN" in l]
        print(f"built {stem}.pdf" + (f"  ({len(warn)} warnings)" if warn else ""))
        for l in warn:
            print("   ", l)
    finally:
        if os.path.exists(os.path.join(work, stem + ".pdf")):
            shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    outdir = os.path.join(REPO, "docs", "pdf")
    if "--out" in args:
        i = args.index("--out"); outdir = os.path.abspath(args[i + 1]); del args[i:i + 2]
    files = CHAPTERS if args == ["--all"] else args
    today = datetime.date.today()
    for f in files:
        build(f, outdir, today)
