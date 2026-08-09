provider "oci" {
  region = local.region
}

locals {
  name   = "ex-lifecycle"
  region = "us-ashburn-1"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-oci-objectstorage-bucket"
    GithubOrg  = "terraform-oci-modules"
  }
}

################################################################################
# Bucket with a lifecycle policy showcasing every OCI action + filter type
################################################################################

module "bucket" {
  source = "../../"

  bucket         = local.name
  compartment_id = var.compartment_id

  versioning = "Enabled"

  lifecycle_rule = [
    # 1. Archive cold objects under "archive/" after 90 days.
    {
      name        = "archive-cold-data"
      action      = "ARCHIVE"
      time_amount = 90
      time_unit   = "DAYS"
      object_name_filter = {
        inclusion_prefixes = ["archive/"]
      }
    },

    # 2. Move "logs/" to Infrequent Access after 30 days, except .tmp files.
    {
      name        = "ia-warm-logs"
      action      = "INFREQUENT_ACCESS"
      time_amount = 30
      time_unit   = "DAYS"
      object_name_filter = {
        inclusion_prefixes = ["logs/"]
        exclusion_patterns = ["*.tmp"]
      }
    },

    # 3. Delete temp/* glob after 7 days.
    {
      name        = "delete-temp-files"
      action      = "DELETE"
      time_amount = 7
      time_unit   = "DAYS"
      object_name_filter = {
        inclusion_patterns = ["temp/*"]
      }
    },

    # 4. Purge previous object versions after 1 year.
    {
      name        = "purge-old-versions"
      action      = "DELETE"
      time_amount = 1
      time_unit   = "YEARS"
      target      = "previous-object-versions"
    },

    # 5. Abort multipart uploads abandoned for more than 3 days.
    {
      name        = "abort-stale-multipart"
      action      = "ABORT"
      time_amount = 3
      time_unit   = "DAYS"
      target      = "multipart-uploads"
    },
  ]

  tags = local.tags
}
