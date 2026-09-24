#!/usr/bin/env python3
"""Checks that every locale has the same keys, __N__ placeholders and rich text tags as English."""
import glob
import re
import sys


def parse(path):
    section, keys = None, {}
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.strip():
            continue
        m = re.match(r"^\[(.+)\]$", line)
        if m:
            section = m.group(1)
            continue
        key, _, value = line.partition("=")
        keys[f"{section}.{key}"] = value
    return keys


def placeholders(s):
    return sorted(re.findall(r"__\d+__", s))


def tags(s):
    return re.findall(r"\[(?:img|color)=[^\]]*\]", s)


en = parse("locale/en/second-dawn.cfg")
ok = True
for path in sorted(glob.glob("locale/*/second-dawn.cfg")):
    lang = path.split("/")[1]
    loc = parse(path)
    problems = []
    problems += [f"missing {k}" for k in sorted(set(en) - set(loc))]
    problems += [f"extra {k}" for k in sorted(set(loc) - set(en))]
    for k in en:
        if k in loc and placeholders(en[k]) != placeholders(loc[k]):
            problems.append(f"placeholders differ in {k}")
        if k in loc and tags(en[k]) != tags(loc[k]):
            problems.append(f"tags differ in {k}")
    print(f"{lang:6} {'ok' if not problems else ''}")
    for p in problems:
        print(f"    {p}")
    ok = ok and not problems
sys.exit(0 if ok else 1)
