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

## How to retrieve old files from versioned bucket
Check that aws commandline tools have been installed before this
```
# This outputs json of all versions
$ aws s3api list-object-versions --bucket your-bucket-name

# This is how you restore older version
# In this example the version we want to restore is rehtEuCbtlaaJWnP0jfdHMQLkyrBPHG_
$ aws s3api get-object --bucket your-bucket-name --key backups/flynn-backup.tar --version-id rehtEuCbtlaaJWnP0jfdHMQLkyrBPHG_ flynn-backup.tar
```

## Maintainers
[@onnimonni](https://github.com/onnimonni)

## License
MIT