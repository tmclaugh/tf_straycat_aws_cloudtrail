# tf_straycat_aws_cloudtrail
Setup a CloudTrail trail.

## Variables
### Required
* ___aws_cloudtrail_name:___ Name of CloudTrail trail.

* ___s3_bucket_name:___ Name of bucket to create to store logs.  Pay attention to the fact that domain name and account name will be prepended to thebucket to help prevent name collisions.

* ___aws_account:___ Name of AWS account.  Used to find remote state information and is prepended to bucket names.

* ___aws_account_id:___ Account ID, used for CloudTrail integration.

* ___aws_region:___ AWS region.  Used to find remote state.

### Optional
* ___s3_bucket_prefix:___ S3 prefix for logs.

* ___enable_logging:___ Enable logging, set to 'false' to Pause logging.

* ___enable_log_file_validation:___ Create signed digest file to validated contents of logs.

* ___include_global_service_events:___ Include evnets from global services such as IAM.

* ___is_multi_region_trail:___ Whether the trail is created in all regions or just the current region.

## Region support
This module defaults to creating multi-region CloudTrails.  The reason for this is you should be monitoring those regions not in use by you to ensure that there is no rogue activity.  Your alerting system should alert when events occur in unexpected regions.
