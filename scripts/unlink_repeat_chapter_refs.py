"""Keep only the first link to each cross-chapter target on a page.

A reference into another chapter renders as a link to that page: a whole chapter
(@sec-inference, <a href="04-Foundation_Inference.html" class="quarto-xref">) or
one of its sections, figures or tables (@sec-3normal, @fig-4two-sampling, with a
#fragment). When a chapter leans on an earlier one, the same target gets linked
again and again, and the links stop pointing anywhere in particular. This
post-render step keeps the first link to each target on a page and turns later
links to that same target into plain text. Quarto still fills in the numbers
("Chapter 4", "Section 3.4"), so renumbering stays automatic.

A link to the chapter as a whole and a link to the chapter's title are the same
target. Different sections, figures and tables of one chapter are different
targets. References to the page's own figures, tables and sections (href="#...")
are never touched.

The first link to a whole chapter also gets the chapter title's id as its
fragment (04-Foundation_Inference.html#sec-inference). Quarto's hover preview for
a link with no fragment shows the top of the page minus its title (the PDF button
and the epigraph); pointed at the title, the preview shows the chapter's name.

Runs as a project post-render script (see _quarto.yml). Quarto lists the files it
just rendered in QUARTO_PROJECT_OUTPUT_FILES; with no list, every page in docs/ is
processed. Running it twice changes nothing the second time.
"""
import glob
import os
import re

XREF = re.compile(r'<a href="(\d\d-[^"#]+\.html)(#[^"]*)?" class="quarto-xref">(.*?)</a>', re.S)
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
        page, frag, inner = m.group(1), m.group(2) or "", m.group(3)
        whole_chapter = frag in ("", "#" + ids.get(page, ""))
        target = page if whole_chapter else page + frag
        if target in seen:
            return inner
        seen.add(target)
        if whole_chapter and page in ids:
            return f'<a href="{page}#{ids[page]}" class="quarto-xref">{inner}</a>'
        return m.group(0)

    return XREF.sub(keep_first, html)


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
