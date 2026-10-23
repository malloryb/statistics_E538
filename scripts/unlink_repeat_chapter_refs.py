"""Keep only the first link to each chapter on a page.

A chapter reference (@sec-inference) renders as a link to the whole chapter,
<a href="04-Foundation_Inference.html" class="quarto-xref"><span>Chapter 4</span></a>.
When a chapter leans on an earlier one, nearly every mention becomes a link, and
the links stop pointing anywhere in particular. This post-render step keeps the
first link to each chapter on a page and turns later ones into plain text. The
chapter number is still filled in by Quarto, so renumbering stays automatic.

Links with a fragment (#fig-..., #tbl-..., #sec-... for a section) point at
something specific and are never touched.

The first link also gets the chapter title's id as its fragment
(04-Foundation_Inference.html#sec-inference). Quarto's hover preview for a link
with no fragment shows the top of the page minus its title (the PDF button and
the epigraph); pointed at the title, the preview shows the chapter's name.

Runs as a project post-render script (see _quarto.yml). Quarto lists the files it
just rendered in QUARTO_PROJECT_OUTPUT_FILES; with no list, every page in docs/ is
processed. Running it twice changes nothing the second time.
"""
import glob
import os
import re

CHAPTER_LINK = re.compile(r'<a href="(\d\d-[^"#]+\.html)" class="quarto-xref">(.*?)</a>', re.S)
TITLE_ID = re.compile(r'<h1 class="title"><span id="([^"]+)" class="quarto-section-identifier">')


def title_ids(outdir="docs"):
    ids = {}
    for path in glob.glob(os.path.join(outdir, "[0-9][0-9]-*.html")):
        with open(path, encoding="utf-8") as fh:
            m = TITLE_ID.search(fh.read())
        if m:
            ids[os.path.basename(path)] = m.group(1)
    return ids


def unlink_repeats(html, ids):
    seen = set()

    def keep_first(m):
        target = m.group(1)
        if target in seen:
            return m.group(2)
        seen.add(target)
        if target in ids:
            return f'<a href="{target}#{ids[target]}" class="quarto-xref">{m.group(2)}</a>'
        return m.group(0)

    return CHAPTER_LINK.sub(keep_first, html)


def main():
    listed = os.environ.get("QUARTO_PROJECT_OUTPUT_FILES", "").split("\n")
    files = [f for f in listed if f.endswith(".html")] or glob.glob("docs/*.html")
    ids = title_ids()
    for path in files:
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as fh:
            html = fh.read()
        new = unlink_repeats(html, ids)
        if new != html:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(new)


if __name__ == "__main__":
    main()
