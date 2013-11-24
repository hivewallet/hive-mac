#!/usr/bin/env python

import sys, re

def header_sort_key(line):
    # Makes sure '<' sorts earlier that '"'.
    return re.sub(r'<', '!', line).lower()

if len(sys.argv) < 2:
    print("Usage: python sort_imports.py FILE")
    exit(1)

file = open(sys.argv[1], "r")

out_lines = []
current_imports = []

lines = file.readlines()
for line in lines:
    in_imports = line.startswith("#import") or line.startswith("#include")
    if in_imports:
        current_imports.append(line)
    else:
        if current_imports != []:
            current_imports.sort(key = header_sort_key)
            out_lines += current_imports
            current_imports = []
        out_lines.append(line)

file.close()

if out_lines != lines:
    print("Rewriting: " + sys.argv[1])
    file = open(sys.argv[1], "w")
    for line in out_lines:
        file.write(line)
    file.close()
