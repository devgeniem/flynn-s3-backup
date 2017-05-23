FROM alpine:3.4

# Add backup script
COPY scripts /scripts

RUN set -x && \

	# Install curl for flynn http api
	apk add --no-cache curl && \

	# Install minio client for transfering files into s3
	curl -L -o /usr/local/bin/mc https://dl.minio.io/client/mc/release/linux-amd64/mc && \
	chmod +x /usr/local/bin/mc && \

	# Set chmod +x to backup.sh
	chmod +x /scripts/backup.sh

ENTRYPOINT /scripts/backup.sh

# This is the time that the bash script waits before backup
# ENV BACKUP_INTERVAL_SECONDS="10800"
