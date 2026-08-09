provider "oci" {
  region = local.region
}

locals {
  name   = "ex-public-access"
  region = "us-ashburn-1"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-oci-objectstorage-bucket"
    GithubOrg  = "terraform-oci-modules"
  }
}

################################################################################
# Two buckets demonstrating each anonymous-access level OCI exposes:
#
# - ObjectRead - anonymous GET + LIST (closest to a public website / asset bucket)
# - ObjectReadWithoutList - anonymous GET, listing denied (asset bucket with no enumeration)
#
# The "private" default (NoPublicAccess) is exercised by examples/simple.
################################################################################

module "public_read" {
  source = "../../"

  bucket         = "${local.name}-read"
  compartment_id = var.compartment_id

  access_type = "ObjectRead"

  tags = local.tags
}

module "public_read_no_list" {
  source = "../../"

  bucket         = "${local.name}-nolist"
  compartment_id = var.compartment_id

  access_type = "ObjectReadWithoutList"

  tags = local.tags
}
