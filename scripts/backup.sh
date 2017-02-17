#!/bin/sh

##
# Somehow cron replaces some environmental things and minio client can't use the 
# s3 host we configured so just use sleep instead
##

# Check requirements
if [ -z "$FLYNN_AUTH_KEY" ]; then
	echo "ERROR: FLYNN_AUTH_KEY must be set so that we can connect to flynn"
	sleep 5
	exit 1
fi

if [ -z "$BACKUP_INTERVAL" ]; then
	echo "ERROR: BACKUP_INTERVAL must be set"
	sleep 5
	exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
	echo "ERROR: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set for connecting to AWS S3"
	sleep 5
	exit 1
fi

if [ -z "$AWS_S3_BUCKET" ]; then
	echo "ERROR: AWS_S3_BUCKET needs to be set so that backups can be saved into bucket"
	sleep 5
	exit 1
fi

# Login to s3
mc --quiet config host add s3 https://s3.amazonaws.com $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY S3v4 --json

# Wait for the backup
sleep $BACKUP_INTERVAL_SECONDS

# Take full backup from flynn
curl -s -u :$FLYNN_AUTH_KEY -o /tmp/flynn-backup.tar http://controller.discoverd/backup

# Debug the backup tar
mc ls /tmp/flynn-backup.tar --json

# Transfer the backup into s3
mc cp /tmp/flynn-backup.tar s3/${AWS_S3_BUCKET}/backups/flynn-backup.tar --json

# Remove the backup file
mc rm /tmp/flynn-backup.tar --json

# Flynn will spin up new backup process to another machine when this exits
exit 0