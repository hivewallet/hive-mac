#!/bin/bash

# generate strings from source code files
echo "Regenerating Localizable.strings..."
find Hive -name '*.m' | xargs genstrings -o Hive/en.lproj

# generate strings from XIBs

for file in `find Hive -name '*.xib' -and -path '*/en.lproj/*'`; do
  strings_file=`echo $file | sed s/\.xib/.strings/`
  echo "Regenerating $strings_file..."
  ibtool --generate-strings-file $strings_file $file
done
