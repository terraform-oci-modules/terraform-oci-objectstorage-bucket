provider "oci" {
  region = local.region
}

locals {
  name   = "ex-par"
  region = "us-ashburn-1"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-oci-objectstorage-bucket"
    GithubOrg  = "terraform-oci-modules"
  }
}

################################################################################
# Bucket with two PARs:
#  - bucket-level: anonymous read + list across the whole bucket
#  - object-level: write to a single object key (upload-only handoff URL)
#
# par_expiry is a plain RFC3339 string (default "2030-01-01T00:00:00Z") so the
# example has no provider dependency beyond oci + random and plans are stable.
################################################################################

module "bucket" {
  source = "../../"

  bucket         = local.name
  compartment_id = var.compartment_id

  preauthenticated_requests = {
    bucket-listing-read = {
      access_type           = "AnyObjectRead"
      time_expires          = var.par_expiry
      bucket_listing_action = "ListObjects"
    }
    upload-handoff = {
      access_type  = "ObjectWrite"
      time_expires = var.par_expiry
      object_name  = "uploads/incoming.bin"
    }
  }

  tags = local.tags
}
