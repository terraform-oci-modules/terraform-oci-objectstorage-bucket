provider "oci" {
  region = var.source_region
}

provider "oci" {
  alias  = "destination"
  region = var.destination_region
}

locals {
  name = "ex-replication"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-oci-objectstorage-bucket"
    GithubOrg  = "terraform-oci-modules"
  }
}

################################################################################
# Destination bucket — must exist in a different region before the source
# bucket's replication policy can reference it.
################################################################################

module "destination_bucket" {
  source = "../../"

  providers = {
    oci = oci.destination
  }

  bucket         = "${local.name}-dst"
  compartment_id = var.compartment_id

  versioning = "Enabled"
  tags       = local.tags
}

################################################################################
# Source bucket with a replication policy pointing at the destination bucket.
# Versioning must be Enabled on the source.
################################################################################

module "source_bucket" {
  source = "../../"

  bucket         = "${local.name}-src"
  compartment_id = var.compartment_id

  versioning = "Enabled"

  replication_policy = {
    name                    = "replicate-to-${var.destination_region}"
    destination_region_name = var.destination_region
    destination_bucket_name = module.destination_bucket.name
  }

  tags = local.tags
}
