#!/bin/sh
set -x

##
# Somehow cron replaces some environmental things and minio client can't use the
# s3 host we configured so just use sleep instead
##

curl -X POST -H 'Content-type: application/json' \
	--data "{\"text\":\"Flynn cluster backups ($ENVIRONMENT) started\"}" \
	$SLACK_STATUS_URL

# Check requirements
if [ -z "$FLYNN_AUTH_KEY" ]; then
	echo "ERROR: FLYNN_AUTH_KEY must be set so that we can connect to flynn"
	sleep 5
	exit 1
fi

if [ -z "$BACKUP_INTERVAL_SECONDS" ]; then
	echo "ERROR: BACKUP_INTERVAL_SECONDS must be set"
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

if [ -z "$ENVIRONMENT" ]; then
	echo "ERROR: ENVIRONMENT needs to be set so that backups can be saved into bucket"
	sleep 5
	exit 1
fi

# Login to s3
mc --quiet config host add s3 https://s3.amazonaws.com $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY S3v4 --json

# Wait for the backup
sleep $BACKUP_INTERVAL_SECONDS

# Take full backup from flynn
curl -s -u :$FLYNN_AUTH_KEY -o /tmp/flynn-backup.tar http://controller.discoverd/backup

if [ $? -ne 0  ]; then
	echo "[ERROR]: Curl failed!"
	curl -X POST -H 'Content-type: application/json' \
		--data "{\"text\":\"Flynn cluster backups ($ENVIRONMENT): curling the backup file failed.\"}" \
		$SLACK_URL
	sleep 5
	exit 1
fi

# Check if the tar file is valid
listing=$(tar -tvf /tmp/flynn-backup.tar)

if [ $? -ne 0  ]; then
	echo "[ERROR]: Tar file is not valid!"
	curl -X POST -H 'Content-type: application/json' \
		--data "{\"text\":\"Flynn cluster backups ($ENVIRONMENT): downloaded tar file is not valid.\"}" \
		$SLACK_URL
	sleep 5
	exit 1
fi

# Check that all necessary files are present
files="postgres.sql.gz mongodb.archive.gz flynn.json"

for file in ${files}; do
	if [[ $ENVIRONMENT != "seamk" || $file != "mongodb.archive.gz" ]]; then
		echo $listing | grep "$file"

		if [ $? -ne 0 ]; then
			echo "[ERROR]: File $file is missing from the tar archive"
			curl -X POST -H 'Content-type: application/json' \
				--data "{\"text\":\"Flynn cluster backups ($ENVIRONMENT): file $file is missing from the tar archive.\"}" \
				$SLACK_URL
			sleep 5
			exit 1
		fi
	fi
done

# Check that the gzip files are valid
cd /tmp

tar -xf flynn-backup.tar

tar -tf /tmp/flynn-backup.tar | cut -d '"' -f 2 | while read file; do
    echo $file | grep ".gz"

	if [ "$?" -ne 1 ]; then
		gunzip -t "/tmp/$file"

		if [ $? -ne 0 ]; then
			echo "[ERROR]: File $file is not a valid gzip file"
			curl -X POST -H 'Content-type: application/json' \
				--data "{\"text\":\"Flynn cluster backups ($ENVIRONMENT): file $file is not a valid gzip file.\"}" \
				$SLACK_URL
			sleep 5
			exit 1
		fi
	fi
done

# Check that the filesize is close enough to the previous
previous=$(mc ls s3/${AWS_S3_BUCKET}/backups/${ENVIRONMENT}/flynn-backup.tar | awk '{print $4}' | sed -e 's/[^0-9]//g')
let current=$(ls -sh /tmp/flynn-backup.tar | sed -e 's/[^0-9]//g')/1000
let diff=$current-$previous
abs=$(echo $diff | tr -d -)
let percentage=$abs*100/$previous

if [ $percentage -gt 20 ]; then
	echo "[NOTICE]: The size of the new backup file [${current}] differs ${percentage}% from the previous one [${previous}]"
	curl -X POST -H 'Content-type: application/json' \
		--data "{\"text\":\"Flynn cluster backups ($ENVIRONMENT): The size of the new backup file [${current}] differs ${percentage}% from the previous one [${previous}].\"}" \
		$SLACK_URL
	sleep 5
fi

# Notify admins if backup fails
if [ -z "$SLACK_URL" ]; then
	echo "ERROR: SLACK_URL must be set for notifying admins about S3 backup"
else
	minimumsize=90000
	actualsize=$(wc -c <"/tmp/flynn-backup.tar")
	if [ $actualsize -ge $minimumsize ]; then
	    echo "[INFO]: Backup succeeded from flynn"
	else
	    echo "[ERROR]: Backup is too small, alerting admins that is wrong..."
	    curl -X POST -H 'Content-type: application/json' \
			--data "{\"text\":\"Flynn cluster backups to AWS S3 bucket: $AWS_S3_BUCKET are failing.\"}" \
	 		$SLACK_URL
	 	sleep 5
	 	exit 1
	fi
fi

# Transfer the backup into s3
transfer=$(mc cp /tmp/flynn-backup.tar s3/${AWS_S3_BUCKET}/backups/${ENVIRONMENT}/flynn-backup.tar --json)
if [ $? -ne 0  ]; then
	echo "[ERROR]: Transfer to S3 failed"
	curl -X POST -H 'Content-type: application/json' \
		--data "{\"text\":\"Flynn cluster backups ($ENVIRONMENT): Transfer to S3 failed: $transfer\"}" \
		$SLACK_URL
	sleep 5
	exit 1
fi

if [ -z "$SLACK_STATUS_URL" ]; then
	echo "ERROR: SLACK_STATUS_URL needs to be set so that status checks can be posted in Slack."
else
	curl -X POST -H 'Content-type: application/json' \
		--data "{\"text\":\"Flynn cluster backups ($ENVIRONMENT) completed\"}" \
		$SLACK_STATUS_URL
fi

# Remove the temp files
rm -rf /tmp/*

# Flynn will spin up new backup process to another machine when this exits
exit 0