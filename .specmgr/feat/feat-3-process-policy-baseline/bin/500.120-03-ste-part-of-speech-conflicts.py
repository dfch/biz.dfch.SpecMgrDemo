#!/usr/bin/env python3
# feat-3-process-policy-baseline, Task 500.120
#
# Lists the words in docs/ that are approved as one part of speech and
# rejected as a different part of speech (for example code, test, use).
# The reviewer examines them in their sentences (rule 1.7 and 1.13).
# It loads the word lists from 500.120-01-ste-word-check.py.
#
# Status: reference only, not a gate. The paths are relative to the
# repository root. See 500.120-01-ste-word-check.py for the limits.
#
# Use:  uv run --with biz-dfch-asdste100mcp python3 500.120-03-ste-part-of-speech-conflicts.py
import os
_here=os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here,"500.120-01-ste-word-check.py")).read().split("if \"--plans\"")[0])
import glob,re,collections
docs=[d for d in sorted(glob.glob(str(ROOT/"docs/*/*.md"))) if "/docs/qa/" not in d]
cnt=collections.Counter(); where=collections.defaultdict(set)
for p in docs:
    t=open(p).read(); t=re.sub(r"^---.*?---","",t,flags=re.S); t=re.sub(r"`[^`]*`","",t)
    t=re.sub(r"<!--.*?-->","",t,flags=re.S)
    for w in re.findall(r"[A-Za-z]+",t):
        lw=w.lower()
        if lw in appr and lw in rej and (appr[lw]!=set() ):
            cnt[lw]+=1; where[lw].add(p.split('/')[-1][:8])
print(len(cnt))
for w,c in cnt.most_common():
    print(f"{w}: n={c} docs={len(where[w])} approved={sorted(appr[w])} rejected={sorted(rej[w])}")
