# Hacky Flynn s3 backup script

This is a docker image which uses minio client to connect into s3 bucket in amazon.

It downloads [Flynn](https://flynn.io) cluster backup tar file from http api and transfers it into append-only versioned s3.

Backups will first get uploaded into highly available `STANDARD` zone in s3.
They are transitioned to `STANDARD_IA` after 60 days.
And then transitioned to `GLACIER` after 120 days.

You can decide when AWS expires old backups from `GLACIER`.

## Usage

### Create and deploy the backup process as app in Flynn
```bash
$ docker build -t devgeniem/flynn-backup .
$ flynn create s3-backup --remote="" 
$ flynn -a s3-backup docker push devgeniem/flynn-backup
```

### Create append only s3 bucket and aws iam user
**Note:** Check that [terraform cli](https://www.terraform.io/) has been installed before this.

```bash
$ cd terraform

# This creates new bucket and aws iam user credentials for the account that you provide
$ terraform apply
```

### Configure the backup process
```bash
# Get the flynn controller AUTH_KEY which you can use as FLYNN_AUTH_KEY later
$ flynn -a controller env get AUTH_KEY

# Setup the backup process
$ flynn -a s3-backup env set \
	FLYNN_AUTH_KEY=auth-key-from-flynn \
	AWS_S3_BUCKET=your-bucket-name \
	AWS_ACCESS_KEY_ID=YYYYYYYYYYYYYYYY \
	AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXX \
	BACKUP_INTERVAL_SECONDS=10800 # Put any interval >1800 here
```

### Start the backup process
```
$ flynn -a s3-backup scale app=1
```

## How to retrieve old backups from versioned bucket
**Note:** Check that [aws commandline tools](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) has been installed before this.

```bash
# This outputs json of all versions
$ aws s3api list-object-versions --bucket your-bucket-name

# This is how you restore older version
# In this example the version we want to restore is rehtEuCbtlaaJWnP0jfdHMQLkyrBPHG_
$ aws s3api get-object --bucket your-bucket-name \
	--key backups/flynn-backup.tar \
	--version-id rehtEuCbtlaaJWnP0jfdHMQLkyrBPHG_ \
	flynn-backup.tar
```

## Maintainers
[@onnimonni](https://github.com/onnimonni)

## License
MIT