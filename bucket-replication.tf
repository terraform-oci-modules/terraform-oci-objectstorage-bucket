################################################################################
# Replication Policy
#
# Maps to the AWS S3 replication_configuration. The destination bucket must
# already exist in the destination region and must not have versioning enabled.
# Unlike S3, OCI does not require versioning on the source bucket.
################################################################################

resource "oci_objectstorage_replication_policy" "this" {
  count = local.create_bucket && var.replication_policy != null ? 1 : 0

  namespace               = local.namespace
  bucket                  = oci_objectstorage_bucket.this[0].name
  name                    = var.replication_policy.name
  destination_region_name = var.replication_policy.destination_region_name
  destination_bucket_name = var.replication_policy.destination_bucket_name
}
