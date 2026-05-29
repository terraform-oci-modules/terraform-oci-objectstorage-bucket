provider "oci" {
  region = local.region
}

locals {
  name   = "ex-simple"
  region = "us-ashburn-1"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-oci-objectstorage-bucket"
    GithubOrg  = "terraform-oci-modules"
  }
}

################################################################################
# Object Storage Bucket
################################################################################

module "bucket" {
  source = "../../"

  bucket         = local.name
  compartment_id = var.compartment_id

  tags = local.tags
}
