#!/bin/bash
# Bash script to get the dropbox_path from the dropbox config database
#  (based on the code in pyDropboxPath.py)
#
# This script requires 'sqlite3' to be installed
# And if you're using Dropbox < 0.8.x or > 1.1.x you'll
# additionally need one of 'recode' or 'uudecode' or 'perl' installed
#
# Post any questions or comments in this forum thread:
# http://forums.dropbox.com/topic.php?id=25709
#
# Written by Andrew Scheller, 2010-10-07, 2010-10-08, 2011-01-01
# Updated 2011-11-25 to work with Dropbox 1.2.x/1.3.x
# Updated 2011-12-11 to add platform-detection so it'll work on MacOSX,
#   added a Python base64 decoder and added better error handling
# This code is in the public domain, feel free to copy and reuse this
# function in your own bash scripts! :-)

function fatal {
  if [ -z "$SCRIPTNAME" ]
  then
    local SCRIPTNAME=$( basename $0 )
  fi
  echo "$SCRIPTNAME: $1" >&2
  exit 1
}

function base64_decode {
  local BASE64VALUE="$1"
  local RECODE=$( which recode )
  local UUDECODE=$( which uudecode )
  local PERL=$( which perl )
  local PYTHON=$( which python )
  if [ "$RECODE" ]
  then
    echo $( echo "$BASE64VALUE" | "$RECODE" /b64.. )
  elif [ "$UUDECODE" ]
  then
    local UUDECODE_STRING=$( printf 'begin-base64 0 -\n%s\n====\n' "$BASE64VALUE" )
    case $OSTYPE in
      linux*)  echo $( echo "$UUDECODE_STRING" | "$UUDECODE" ) ;;
      darwin*) echo $( echo "$UUDECODE_STRING" | "$UUDECODE" -p ) ;;
      *)       fatal "Unsupported platform $OSTYPE" ;;
    esac
  elif [ "$PERL" ]
  then
    echo $( "$PERL" -MMIME::Base64 -e "print decode_base64('$BASE64VALUE')" )
  elif [ "$PYTHON" ]
  then
    echo $( "$PYTHON" -c "import base64; print base64.b64decode('$BASE64VALUE')" )
  else
    fatal "Please install one of either recode, uudecode, perl or python"
  fi
}

function get_dropbox_folder {
  local SQLITE3=$( which sqlite3 )
  if [ -z "$SQLITE3" ]
  then
    fatal "Please install sqlite3"
  fi

  # which database have we got?
  if [ -f "$HOME/.dropbox/info.json" ]
  then
    info="$HOME/.dropbox/info.json"
    DROPBOX_FOLDER=$(cat "$info" | grep '"personal": {"path":' | sed -E -e 's/.*"personal": {"path": "([^"]+)".*/\1/')
    return
  elif [ -f "$HOME/.dropbox/config.db" ]
  then
    local DBFILE="$HOME/.dropbox/config.db"
    local DBVER=$( "$SQLITE3" -noheader "$DBFILE" 'SELECT value FROM config WHERE key="config_schema_version"' )
  elif [ -f "$HOME/.dropbox/dropbox.db" ]
  then
    local DBFILE="$HOME/.dropbox/dropbox.db"
    local DBVER=0
  else
    fatal "Dropbox database not found, is dropbox installed?"
  fi

  # get the desired value
  if [ $DBVER -eq 0 ]
  then
    local DBVALUE=$( "$SQLITE3" -noheader "$DBFILE" 'SELECT value FROM config WHERE key="dropbox_path"' )
  elif [ $DBVER -eq 1 ]
  then
    local DBVALUE=$( "$SQLITE3" -noheader "$DBFILE" 'SELECT value FROM config WHERE key="dropbox_path"' )
  elif [ $DBVER -eq 2 ]
  then
    # Drop through to reading it from host.db
    local DBVALUE=
  else
    fatal "Unhandled DB schema version $DBVER"
  fi

  if [ -z "$DBVALUE" ]
  then
    # value not set, read value from host.db instead
    if [ -f "$HOME/.dropbox/host.db" ]
    then
      local DBFILE="$HOME/.dropbox/host.db"
      local DBVALUE=$( tail -1 "$DBFILE" )
      DROPBOX_FOLDER=$( base64_decode "$DBVALUE" )
      local RC=$?
      if [ "$RC" -ne 0 ]
      then
        exit "$RC"
      fi
    else
      # just guess!!
      if [ -d "$HOME/Dropbox" ]
      then
        DROPBOX_FOLDER="$HOME/Dropbox"
      else
        fatal "Couldn't determine location of your dropbox folder"
      fi
    fi
  else
    # decode the value as necessary
    if [ $DBVER -eq 0 ]
    then
      local PICKLED=$( base64_decode "$DBVALUE" )
      local RC=$?
      if [ "$RC" -ne 0 ]
      then
        exit "$RC"
      fi
      DROPBOX_FOLDER=$( echo "$PICKLED" | head -1 | sed s/.// )
    elif [ $DBVER -eq 1 ]
    then
      DROPBOX_FOLDER="$DBVALUE"
    fi
  fi
}


if [ -z "$1" ]
then
  get_dropbox_folder
  echo "$DROPBOX_FOLDER"
elif [ "$1" == "-v" ]
then
  get_dropbox_folder
  echo "Location of dropbox folder for '$USER' is: '$DROPBOX_FOLDER'"
  if [ ! -d "$DROPBOX_FOLDER" ]
  then
    echo "but it appears not to exist!"
  fi
fi
