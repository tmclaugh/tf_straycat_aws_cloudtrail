// Create a CloudTrail

// Variables
variable "aws_account" {
  type = "string"
  description = "Used for naming S3 bucket in tf_straycat_aws_s3"
}

variable "aws_account_id" {
  type = "string"
  description = "Used for CloudTrail role."
}

variable "aws_region" {
  type = "string"
  description = "Used for finding root state in tf_straycat_aws_s3"
}

variable "aws_cloudtrail_name" {
  type = "string"
  description = "Name of CloudTrail trail."
}

variable "s3_bucket_name" {
  type = "string"
  description = "S3 Bucket for logs"
}

variable "enable_logging" {
  description = "Enable logging, set to 'false' to pause logging."
  default = true
}

variable "enable_log_file_validation" {
  description = "Create signed digest file to validated contents of logs."
  default = true
}

variable "include_global_service_events" {
  description = "include evnets from global services such as IAM."
  default = true
}

variable "is_multi_region_trail" {
  description = "Whether the trail is created in all regions or just the current region."
  default = false
}


// Resources
module "aws_cloudtrail_s3_bucket" {
  source = "github.com/tmclaugh/tf_straycat_aws_s3"
  s3_bucket_name = "${var.s3_bucket_name}"
  versioning = true
  aws_account = "${var.aws_account}"
  aws_region = "${var.aws_region}"
}

# FIXME: Need to figure out how to pass in the name of the S3 bucket that has
# yet to be resolved due to our name mangling.
resource "aws_s3_bucket_policy" "bucket" {
  bucket = "${module.aws_cloudtrail_s3_bucket.bucket_id}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${module.aws_cloudtrail_s3_bucket.bucket_id}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${module.aws_cloudtrail_s3_bucket.bucket_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "ct" {
  name = "/aws/cloudtrail/${var.aws_cloudtrail_name}"
  tags {
    terraform = "true"
  }
}

resource "aws_iam_role" "ct" {
  name = "cloudtrail-to-cloudwatch-${var.aws_cloudtrail_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ct" {
  name = "cloudtrail-to-cloudwatch-${var.aws_cloudtrail_name}"
  description = "Deliver logs from CloudTrail to CloudWatch."
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailCreateLogStream",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream"
      ],
      "Resource": [
        "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/cloudtrail/${var.aws_cloudtrail_name}:log-stream:${var.aws_account_id}_CloudTrail_${var.aws_region}*"
      ]
    },
    {
      "Sid": "AWSCloudTrailPutLogEvents",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/cloudtrail/${var.aws_cloudtrail_name}:log-stream:${var.aws_account_id}_CloudTrail_${var.aws_region}*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ct" {
  role = "${aws_iam_role.ct.name}"
  policy_arn = "${aws_iam_policy.ct.arn}"
}

resource "aws_cloudtrail" "ct" {
  name                          = "${var.aws_cloudtrail_name}"
  s3_bucket_name                = "${module.aws_cloudtrail_s3_bucket.bucket_id}"
  enable_logging                = "${var.enable_logging}"
  enable_log_file_validation    = "${var.enable_log_file_validation}"
  include_global_service_events = "${var.include_global_service_events}"
  is_multi_region_trail         = "${var.enable_log_file_validation}"
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.ct.arn}"
  cloud_watch_logs_role_arn     = "${aws_iam_role.ct.arn}"
  depends_on                    = ["aws_s3_bucket_policy.bucket"]
}


// Outputs
output "cloudtrail_id" {
  value = "${aws_cloudtrail.ct.id}"
}

output "cloudtrail_home_region" {
  value = "${aws_cloudtrail.ct.home_region}"
}

output "cloudtrail_arn" {
  value = "${aws_cloudtrail.ct.arn}"
}

output "iam_role_cloudtrail_arn" {
  value = "${aws_iam_role.ct.arn}"
}

output "cloudwatch_log_group_arn" {
  value = "${aws_cloudwatch_log_group.ct.arn}"
}

output "s3_bucket_id" {
  value = "${module.aws_cloudtrail_s3_bucket.bucket_id}"
}

output "s3_bucket_arn" {
  value = "${module.aws_cloudtrail_s3_bucket.bucket_arn}"
}

