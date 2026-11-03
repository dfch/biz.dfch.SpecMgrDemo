#!/usr/bin/env python3
# feat-3-process-policy-baseline, Task 500.120
#
# Lists sentences with more than 25 words and sentences with a passive verb
# (a pattern search, not a grammar check). The reviewer examines the results
# (rules 3.6, 5.1 and 6.3). Reads docs/ and skips docs/qa.
#
# Status: reference only, not a gate. The paths are relative to the
# repository root. See 500.120-01-ste-word-check.py for the limits.
#
# Use:  uv run --with biz-dfch-asdste100mcp python3 500.120-02-ste-passive-and-long-sentences.py
import re,glob,collections
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
docs=[d for d in sorted(glob.glob(str(ROOT/"docs/*/*.md"))) if "/docs/qa/" not in d]
PASS=re.compile(r"\b(is|are|was|were|be|been|being)\s+(\w+ed|made|written|done|given|shown|set|run|built|known|seen|taken|kept|found|used)\b",re.I)
long=[];passv=[];cnt=collections.Counter()
for p in docs:
    t=open(p).read(); t=re.sub(r"^---.*?---","",t,flags=re.S); t=re.sub(r"```.*?```","",t,flags=re.S)
    t=re.sub(r"<!--.*?-->","",t,flags=re.S)
    n=p.split("/")[-1][:12]
    for line in t.splitlines():
        s=line.strip()
        if not s or s.startswith("#") or s.startswith("|"): continue
        s=re.sub(r"^[-*\d.]+\s+","",s)
        for sent in re.split(r"(?<=[.!?])\s+",s):
            w=re.findall(r"[A-Za-z0-9'-]+",sent)
            if len(w)>25: long.append((len(w),n,sent[:110]))
            if PASS.search(sent): passv.append((n,sent[:110]))
print("LONG",len(long)); 
for x in sorted(long,reverse=True)[:60]: print(x)
print("PASSIVE",len(passv))
c=collections.Counter(n for n,_ in passv); print(c.most_common(40))
for x in passv[:25]: print(x)
