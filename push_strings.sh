#!/bin/bash

if [ $(echo "$@" | grep "\-\-help") ]; then
  tx push "$@"
else
  ./update_strings.rb -d
  tx push "$@"
  ./update_strings.rb
fi
