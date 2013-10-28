#!/bin/bash

for file in `find Hive -name '*.xib'`; do
  strings_file=`echo $file | sed 's/\.xib/.strings/'`
  original_file=`echo $file | sed -E 's/([[:alpha:]]|\-)+\.lproj/en.lproj/'`
  if [ "$file" != "$original_file" ]; then
    echo "Updating $file..."
    ibtool --strings-file $strings_file --write $file $original_file
  fi
done
