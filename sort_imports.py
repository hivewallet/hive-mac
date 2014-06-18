#!/usr/bin/env python

import sys, re

def header_sort_key(line):
    """Makes sure '<' sorts earlier that '"'."""

    return re.sub(r'<', '!', line).lower()

def sort_imports():
    """Sorts import statements according to file passed from command line."""

    if len(sys.argv) < 2:
        print("Usage: python sort_imports.py FILE")
        exit(1)

    with open(sys.argv[1], "r") as readable_file:
        out_lines = []
        current_imports = []
        lines = readable_file.readlines()

        for line in lines:
            in_imports = line.startswith("#import") or line.startswith("#include")
            if in_imports:
                current_imports.append(line)
            else:
                if current_imports != []:
                    current_imports.sort(key=header_sort_key)
                    out_lines += current_imports
                    current_imports = []
                out_lines.append(line)

    if out_lines != lines:
        print("Rewriting: " + sys.argv[1])

        with open(sys.argv[1], "w") as writeable_file:
            for line in out_lines:
                writeable_file.write(line)

if __name__ == "__main__":
    sort_imports()
