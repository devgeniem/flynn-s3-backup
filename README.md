# Flynn backup script

This is a docker image which uses minio client to connect into s3 bucket in amazon.

It downloads flynn cluster backup tar file from http api and transfers that into s3.

## Usage

### Create and deploy the backup process
```
$ docker build -t devgeniem/flynn-backup .
$ flynn create s3-backup --remote="" 
$ flynn -a s3-backup docker push devgeniem/flynn-backup
```


### Configure the backup process
```
# Get the flynn controller AUTH_KEY which you can use as FLYNN_AUTH_KEY later
$ flynn -a controller env get AUTH_KEY

# Setup the backup process
$ flynn -a s3-backup env set \
	FLYNN_AUTH_KEY=auth-key-from-flynn \
	AWS_S3_BUCKET=your-bucket-name \
	AWS_ACCESS_KEY_ID=YYYYYYYYYYYYYYYY \
	AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXX \
	BACKUP_INTERVAL_SECONDS=10800 \ # Put any interval >1800 here
```

## Maintainers
[@onnimonni](https://github.com/onnimonni)

## License
MIT