# This file creates versioned s3 bucket named ${var.aws_bucket_name}.
# Assets in the bucket will be moved into cheaper aws storage GLACIER after 120 days
# The bucket automatically expires/deletes file versions which are 3 years old

resource "aws_s3_bucket" "backup" {
    bucket = "${var.aws_bucket_name}"
    acl = "private"
    region = "${var.aws_region}"

    tags {
        Name = "Flynn Production Backups"
        Environment = "Prod"
    }
    versioning {
        enabled = true
    }

    lifecycle_rule {
        id = "backup"
        prefix = "backups/"
        enabled = true

        transition {
            days = 60
            storage_class = "STANDARD_IA"
        }
        transition {
            days = 120
            storage_class = "GLACIER"
        }
        expiration {
            # Keep backups for 3 years
            days = "${var.aws_bucket_expiration_after_days}"
        }
    }
}

resource "aws_iam_user" "backup_user" {
    name = "${var.aws_bucket_name}-user"
}

resource "aws_iam_access_key" "backup_user" {
    user = "${aws_iam_user.backup_user.name}"
}

resource "aws_iam_user_policy" "backup_append_only" {
    name = "Backup-Append-Only"
    user = "${aws_iam_user.backup_user.name}"

    # Append-only policy
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.backup.bucket}",
                "arn:aws:s3:::${aws_s3_bucket.backup.bucket}/*"
            ]
        }
    ]
}
EOF
}
