#!/bin/sh

#  get_gdrive_folder.sh
#  Hive
#
#  Created by Jakub Suder on 22/07/14.
#  Copyright (c) 2014 Hive Developers. All rights reserved.

CONFIG_FILE="$HOME/Library/Application Support/Google/Drive/sync_config.db"
COMMAND="SELECT data_value FROM data WHERE entry_key = 'local_sync_root_path';"

if [ -f "$CONFIG_FILE" ]; then
    sqlite3 -noheader "$CONFIG_FILE" "$COMMAND"
else
    echo "File $CONFIG_FILE doesn't exist." >&2
    exit 1
fi
