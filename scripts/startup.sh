#!/bin/sh

echo "Starting s3 backup process..."
# Check requirements
if [ -z "$FLYNN_AUTH_KEY" ]; then
	echo "ERROR: FLYNN_AUTH_KEY must be set so that we can connect to flynn"
	exit 1
fi

if [ -z "$BACKUP_INTERVAL" ]; then
	echo "ERROR: BACKUP_INTERVAL must be set"
	exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
	echo "ERROR: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set for connecting to AWS S3"
	exit 1
fi

if [ -z "$AWS_S3_BUCKET" ]; then
	echo "ERROR: AWS_S3_BUCKET needs to be set so that backups can be saved into bucket"
	exit 1
fi

# Login to s3
mc config host add s3 https://s3.amazonaws.com $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY S3v4 --json

# Run backup script in defined interval
echo "$BACKUP_INTERVAL /scripts/backup-cron.sh" > /var/spool/cron/crontabs/root

# Cron won't work without newline in the end
echo "" >> /var/spool/cron/crontabs/root

# Run the cron daemon
exec crond -l 2 -f