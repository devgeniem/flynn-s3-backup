#!/bin/sh

##
# This script takes full flynn cluster backup and dumps it into s3 bucket
##

# Take full backup from flynn
curl -s -u :$FLYNN_AUTH_KEY -o /tmp/flynn-backup.tar http://controller.discoverd/backup

# Debug the backup tar
mc ls /tmp/flynn-backup.tar --json

# Transfer the backup into s3
mc cp /tmp/flynn-backup.tar s3/${AWS_S3_BUCKET}/backups/flynn-backup.tar --json --debug -C /.mc

# Remove the backup file
mc rm /tmp/flynn-backup.tar --json