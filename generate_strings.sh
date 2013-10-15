#!/bin/bash

# generate strings from source code files
echo "Regenerating Localizable.strings..."
find Hive -name '*.m' | xargs genstrings -o Hive/en.lproj
iconv -f UTF-16 -t UTF-8 Hive/en.lproj/Localizable.strings > Hive/en.lproj/Localizable.strings.8
mv Hive/en.lproj/Localizable.strings.8 Hive/en.lproj/Localizable.strings

# generate strings from XIBs

for file in `find Hive -name '*.xib' -and -path '*/en.lproj/*'`; do
  strings_file=`echo $file | sed s/\.xib/.strings/`
  echo "Regenerating $strings_file..."
  ibtool --generate-strings-file $strings_file $file
  iconv -f UTF-16 -t UTF-8 $strings_file > $strings_file.8
  mv $strings_file.8 $strings_file
done
