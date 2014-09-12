#!/bin/bash

while getopts “l:f:” OPTION
do
  case $OPTION in
    l)
      LOCALE=$OPTARG
      ;;
    f)
      FILENAME=$OPTARG
      ;;
  esac
done

# pass as e.g. "-f MainMenu"
if [ "$FILENAME" ]; then
  QUERY=(-iname "*$FILENAME*.xib")
else
  QUERY=(-name "*.xib")
fi

# pass as e.g. "-l pl"
if [ "$LOCALE" ]; then
  QUERY+=(-and -path "*/$LOCALE.lproj/*")
fi

for file in $(find Hive "${QUERY[@]}"); do
  strings_file=`echo $file | sed 's/\.xib/.strings/'`
  original_file=`echo $file | sed -E 's/([[:alpha:]]|\-)+\.lproj/en.lproj/'`
  if [ "$file" != "$original_file" ]; then
    echo "Updating $file..."
    if [ -f "$strings_file" ]; then
        ibtool --strings-file $strings_file --write $file $original_file
    else
        ibtool --write $file $original_file
    fi

    # ignore files with only irrelenvant changes
    changes=`git diff "$file" | egrep "^\+[^+]" | grep -v "<document" | grep -v "</document>" | grep -v "<plugIn"`

    if [ ! "$changes" ]; then
        git checkout HEAD "$file"
    fi
  fi
done
