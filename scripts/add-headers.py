#!/usr/bin/env python3
"""Adds the standard Xcode file header to every Swift file that lacks one.

    python3 scripts/add-headers.py                  # whole repo
    AUTHOR="Jane Doe" python3 scripts/add-headers.py

Header (same format Xcode writes, Buddhist calendar date):

    //
    //  FileName.swift
    //  EventPushStarterKit
    //
    //  Created by Komsit Chusangthong on 16/10/2569 BE.
    //
"""
import datetime, glob, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT = next((p[:-10] for p in os.listdir(ROOT) if p.endswith(".xcodeproj")), "App")
AUTHOR = os.environ.get("AUTHOR", "Komsit Chusangthong")
today = datetime.date.today()
DATE = f"{today.day:02d}/{today.month:02d}/{today.year + 543} BE"

def header(name):
    return f"//\n//  {name}\n//  {PROJECT}\n//\n//  Created by {AUTHOR} on {DATE}.\n//\n\n"

def has_header(text, name):
    return text.startswith(f"//\n//  {name}\n")

changed = 0
patterns = ["App/Sources/**/*.swift", "Modules/Sources/**/*.swift", "Modules/Tests/**/*.swift", "Templates/Project/**/*.swift", "Templates/Extensions/**/*.swift"]
for pattern in patterns:
    for path in glob.glob(os.path.join(ROOT, pattern), recursive=True):
        name = os.path.basename(path)
        with open(path, encoding="utf-8") as f:
            text = f.read()
        if has_header(text, name):
            continue
        # Replace an old/partial header block at the very top, if any.
        text = re.sub(r"\A(//[^\n]*\n)+\n?", "", text) if text.startswith("//\n//  ") else text
        with open(path, "w", encoding="utf-8") as f:
            f.write(header(name) + text.lstrip("\n"))
        changed += 1
print(f"headers added to {changed} files")
