provider "oci" {
  region = local.region
}

locals {
  name   = "ex-complete"
  region = "us-ashburn-1"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-oci-objectstorage-bucket"
    GithubOrg  = "terraform-oci-modules"
  }
}

################################################################################
# Object Storage Bucket - all OCI-mappable features turned on
################################################################################

module "bucket" {
  source = "../../"

  bucket         = local.name
  compartment_id = var.compartment_id

  access_type           = "NoPublicAccess"
  storage_tier          = "Standard"
  auto_tiering          = "InfrequentAccess"
  object_events_enabled = true
  kms_key_id            = var.kms_key_id

  # NOTE: OCI does not allow retention_rules on versioning-enabled buckets.
  # versioning is demonstrated in examples/lifecycle instead.

  metadata = {
    owner       = "platform-team"
    environment = "example"
  }

  # Object Lock / WORM equivalent - duration is required by the OCI API.
  retention_rules = [
    {
      display_name = "thirty-day-retention"
      time_amount  = 30
      time_unit    = "DAYS"
    },
  ]

  # Lifecycle policy.
  # NOTE: target = "previous-object-versions" requires versioning = "Enabled"
  # and is not included here. See examples/lifecycle for that scenario.
  # NOTE: cannot use action = "INFREQUENT_ACCESS" in a lifecycle rule when
  # auto_tiering = "InfrequentAccess" is already set on the bucket.
  lifecycle_rule = [
    {
      name        = "archive-after-60d"
      action      = "ARCHIVE"
      time_amount = 60
      time_unit   = "DAYS"
    },
    {
      name        = "abort-stale-multipart-uploads"
      action      = "ABORT"
      time_amount = 7
      time_unit   = "DAYS"
      target      = "multipart-uploads"
    },
  ]

  tags         = local.tags
  defined_tags = var.defined_tags
}
