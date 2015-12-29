#!/bin/bash
#
# Cas van der Weegen
# <vdweegen@protonmail.ch>
# 
# Description: Creates backups for a MongoDB ReplicaSet
#
# Licence:
#
# The MIT License (MIT)
# Copyright (c) 2015 Cas van der Weegen <vdweegen@protonmail.ch>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"),to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
# OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

# Settings
declare -a HOSTS=('<HOST1>:<PORT1>' '<HOST2>:<PORT2>' '<HOST3>:<PORT3>')
REPLICASET=""                   # ReplicaSet
AUTH_DB=""                      # Database to Authenticate to
DATABASE=""                     # Database to Backup
USERNAME=""                     # Username (optional)
PASSWORD=""                     # Password (optional)

TODAY=$(date +"%m-%d-%Y")       # Contruct todays Date

LOG_PATH="./logs"               # Path to save the logfiles to
LOG_FILE=$TODAY".log"           # Log Filename
LOG=$LOG_PATH"/"$LOG_FILE       # Complete Log

BACKUP_PATH="./backups"         # Backup Path
MONGODUMP=""$(which mongodump)  # Get mongodump binary location
TAR=""$(which tar)              # Get tar binary location

if [ -d "$BACKUP_PATH" ]; then
    echo "Starting backup on ReplicaSet \"$REPLICASET\" with ${#HOSTS[@]} hosts" >> $LOG
    HOSTLINE=$REPLICASET"/"${HOSTS[@]:0:${#HOSTS[@]}}    
    TMP="backup-$TODAY" # tmp dir to store backups
    
    if [ "$USERNAME" != "" ] || [ "$PASSWORD" != "" ]; then # Authenticated Connection
        $MONGODUMP -h ${HOSTLINE// /,} -d $DATABASE -u $USERNAME -p $PASSWORD --authenticationDatabase $AUTH_DB -o $TMP >> /dev/null
    else # Unauthenticated Connection
        $MONGODUMP -h ${HOSTLINE// /,} -d $DATABASE -o $TMP >> /dev/null
    fi
    
    # Assume the Dump was complete, verify integrity
    if [ -d "$TMP" ]; then
        $TAR -czf $BACKUP_PATH"/"$TODAY.tar.gz $TMP --remove-files >> /dev/null
        
        if [ -f "$BACKUP_PATH/$TODAY.tar.gz" ]; then
            echo "Backup Succesfull: $(du -h "$BACKUP_PATH/$TODAY.tar.gz")" >> $LOG
        else
            echo "Backup Failed, could not find tar" >> $LOG
        fi
    else
        echo "Backup Failed, could not find tmp directory" >> $LOG
    fi
else
    echo "Backup Failed, could not cd to \"$BACKUP_PATH\"" >> $LOG
fi
