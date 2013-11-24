#!/bin/bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for file in $(find "$script_dir/Hive" -name "*.[mh]"); do
  "$script_dir/sort_imports.py" "$file"
done
