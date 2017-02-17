output "s3-bucket-name" {
    value = "${var.aws_bucket_name}"
}

output "s3-user-access-key" {
    value = "${aws_iam_access_key.backup_user.id}"
}

output "s3-user-secret-key" {
    value = "${aws_iam_access_key.backup_user.secret}"
}
