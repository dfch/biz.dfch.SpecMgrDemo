#!/usr/bin/env python3
# feat-3-process-policy-baseline, Task 500.120
#
# STE word check of the specmgr documents in docs/ (docs/qa is skipped).
# It compares each word with the asdste100 base dictionary, the technical
# words, the EARS, CPRE and RFC 2119 lists, and the terminology register in
# terminology/en/. It prints the words that are only rejected, and the
# words that are not known.
#
# Status: reference only. It is NOT a gate and CI does not start it (the
# owner put the STE gate and the register script on hold on 2026-11-03).
# It does not examine grammar (tenses, passive voice, sentence length).
#
# Limits:
#   - The paths below are fixed for the machine of the author. The path of
#     the base dictionary is in the cache of uv and changes with the package.
#   - It finds known words by simple suffix rules, so it can show a
#     false result.
#   - It does not read the feature plans in .specmgr/. Change the glob in
#     the line that sets `docs` to include them.
#
# Use:  python3 500.120-01-ste-word-check.py
import json,re,glob,collections,sys
B="/home/user/.cache/uv/archive-v0/hGlHdr7uTYq3wLtr/lib/python3.13/site-packages/biz/dfch/asdste100vocab/data/"
T="/home/user/src/biz.dfch.AsdSte100TechnicalWords/src/biz/dfch/asdste100technicalwords/data/"
R="/home/user/src/biz.dfch.SpecMgrDemo/terminology/en/"
files=[B+"asdste100_issue9_base.jsonl",B+"asdste100_issue9_technical_words.jsonl",T+"vocab-ears.jsonl",T+"cpre-glossary-en.jsonl",T+"vocab-rfc2119.jsonl",R+"technical-nouns.jsonl",R+"technical-verbs.jsonl"]
appr=collections.defaultdict(set); rej=collections.defaultdict(set)
def add(d,n,t):
    for w in re.split(r"[\s/]+",n.lower()):
        w=w.strip(".,;:()'\"")
        if w: d[w].add(t)
for f in files:
    for l in open(f):
        r=json.loads(l); d=appr if r['status']=='approved' else rej
        add(d,r['name'],r['type_'])
        for s in r.get('spellings',[]) or []:
            add(d,s if isinstance(s,str) else s.get('name',''),r['type_'])
def known(w):
    c=[w]
    for suf,rep in (("ies","y"),("es",""),("s",""),("ed",""),("ed","e"),("ing",""),("ing","e"),("ly",""),("er",""),("d",""),("ied","y")):
        if w.endswith(suf) and len(w)-len(suf)>=2: c.append(w[:-len(suf)]+rep)
    # doubled consonant
    for x in list(c):
        if len(x)>3 and x[-1]==x[-2]: c.append(x[:-1])
    return c
docs=sorted(glob.glob("/home/user/src/biz.dfch.SpecMgrDemo/docs/*/*.md")) ; docs=[d for d in docs if "/docs/qa/" not in d]
unk=collections.defaultdict(set); rj=collections.defaultdict(set)
for p in docs:
    t=open(p).read()
    t=re.sub(r"^---.*?---","",t,flags=re.S)
    t=re.sub(r"```.*?```","",t,flags=re.S)
    t=re.sub(r"`[^`]*`","",t)
    t=re.sub(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}","",t)
    t=re.sub(r"https?://\S+","",t)
    t=re.sub(r"\[([^\]]*)\]\([^)]*\)",r"\1",t)
    t=re.sub(r"(?m)^(- )?(GOL|PRB|QA|UC|REQ|RSK|DEC|ADR|VCR|SYSRS|TXT|FEAT)\s*:?","",t)
    name=p.split("/")[-1][:8]
    for w in re.findall(r"[A-Za-z][A-Za-z'-]*",t):
        lw=w.lower().strip("'-")
        if len(lw)<2: continue
        cands=known(lw)
        if any(c in appr for c in cands): continue
        if any(c in rej for c in cands): rj[lw].add(name)
        else: unk[lw].add(name)
print("REJECTED-ONLY:",len(rj))
for w,s in sorted(rj.items()): print(" ",w,len(s))
print("UNKNOWN:",len(unk))
print(" ".join(f"{w}({len(s)})" for w,s in sorted(unk.items())))
