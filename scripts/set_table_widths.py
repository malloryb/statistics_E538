#!/usr/bin/env python3
"""Size pipe-table columns by their contents, not their headers.

Pandoc sets a pipe table's column widths from the dashes in its separator row
whenever any row is wider than 72 characters. Typed by hand, those dashes tend to
follow the header, so a long header with short entries gets the most room.
This sets the dashes from the cell contents: short columns just wide enough not
to wrap, long-text columns sharing the rest by their average length.

    python3 scripts/set_table_widths.py           # list tables it would change
    python3 scripts/set_table_widths.py --apply   # rewrite their separator rows
"""
import re,sys,glob
def vis(s):
    s=re.sub(r'`r [^`]*`','00.00',s)
    s=re.sub(r'@(fig|tbl|sec)-[\w-]+','Figure 10.10',s)
    s=re.sub(r'\$([^$]*)\$',lambda m: 'x'*max(1,len(re.sub(r'\\[a-zA-Z]+|[{}_^]','',m.group(1)))//1),s)
    s=re.sub(r'\[([^\]]*)\]\([^)]*\)',r'\1',s)
    s=s.replace('**','').replace('`','')
    return len(s.strip())
SEP=re.compile(r'^\|(\s*:?-+:?\s*\|)+\s*$')
def cells(line): return [c.strip() for c in line.strip().strip('|').split('|')]
def plan(path):
    L=open(path).read().split('\n'); out=[]
    i=0
    while i<len(L):
        if i>0 and SEP.match(L[i]) and L[i-1].lstrip().startswith('|'):
            hdr=cells(L[i-1]); sep=cells(L[i]); j=i+1; rows=[]
            while j<len(L) and L[j].lstrip().startswith('|'): rows.append(cells(L[j])); j+=1
            n=len(sep)
            if all(len(r)==n for r in rows) and len(hdr)==n:
                longest=max(len(x) for x in [L[i-1]]+L[i+1:j])
                if longest>72:   # pandoc uses separator-relative widths only then
                    B=90
                    mx=[]; mean=[]; hw=[]
                    for k in range(n):
                        v=[vis(r[k]) for r in rows] or [1]
                        mx.append(max(v)); mean.append(sum(v)/len(v))
                        hw.append(max([vis(x) for x in hdr[k].split()]+[3]))
                    if sum(max(a,b) for a,b in zip(mx,hw))<=B:
                        w=[max(a,b) for a,b in zip(mx,hw)]
                    else:
                        short=[k for k in range(n) if max(mx[k],hw[k])<=18]
                        w=[0]*n
                        for k in short: w[k]=max(mx[k],hw[k])
                        rest=B-sum(w[k] for k in short); lk=[k for k in range(n) if k not in short]
                        tm=sum(mean[k] for k in lk) or 1
                        for k in lk: w[k]=max(hw[k],12,rest*mean[k]/tm)
                    tot=sum(w); dashes=[max(3,round(60*x/tot)) for x in w]
                    old=[len(s.replace(':','')) for s in sep]
                    oldfrac=[o/sum(old) for o in old]; newfrac=[d/sum(dashes) for d in dashes]
                    if max(abs(a-b) for a,b in zip(oldfrac,newfrac))>0.08:
                        newsep='|'+'|'.join((':' if s.startswith(':') else '')+'-'*d+(':' if s.endswith(':') and len(s)>1 else '') for s,d in zip(sep,dashes))+'|'
                        out.append((i,L[i-1][:70],[round(x,2) for x in oldfrac],[round(x,2) for x in newfrac],newsep))
            i=j; continue
        i+=1
    return L,out
if __name__=='__main__':
    apply='--apply' in sys.argv
    for p in sorted(glob.glob('[01]*.qmd'))+['choosing-a-test.qmd','glossary.qmd']:
        L,out=plan(p)
        for i,h,o,n,ns in out:
            print(p,i+1,'|',h); print('    old',o,'new',n)
            if apply: L[i]=ns
        if apply and out: open(p,'w').write('\n'.join(L))
