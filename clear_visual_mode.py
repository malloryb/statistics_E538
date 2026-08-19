#!/usr/bin/env python3
"""Flip RStudio's persisted per-document visual-mode flag to false.
RUN ONLY WITH RSTUDIO FULLY QUIT -- it rewrites its state on exit."""
import glob, json, os

changed = 0
targets = glob.glob('.Rproj.user/*/sources/prop/*') + \
          glob.glob('.Rproj.user/*/sources/session-*/*')
for p in targets:
    if os.path.basename(p) in ('INDEX',) or p.endswith('-contents') or 'lock_file' in p:
        continue
    try:
        with open(p) as fh:
            d = json.load(fh)
    except Exception:
        continue
    hit = False
    if d.get('rmdVisualMode') == 'true':
        d['rmdVisualMode'] = 'false'; hit = True
    props = d.get('properties')
    if isinstance(props, dict) and props.get('rmdVisualMode') == 'true':
        props['rmdVisualMode'] = 'false'; hit = True
    if hit:
        with open(p, 'w') as fh:
            json.dump(d, fh, indent=4)
        changed += 1
print(f"cleared visual-mode flag in {changed} state file(s)")
