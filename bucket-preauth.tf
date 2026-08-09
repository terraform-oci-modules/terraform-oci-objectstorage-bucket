################################################################################
# Pre-Authenticated Requests (PARs)
#
# Rough equivalent of AWS S3 presigned URLs: time-limited, credential-free
# access to a bucket or a specific object. Each PAR exposes an access_uri.
################################################################################

resource "oci_objectstorage_preauthrequest" "this" {
  for_each = local.create_bucket ? var.preauthenticated_requests : {}

  namespace             = local.namespace
  bucket                = oci_objectstorage_bucket.this[0].name
  name                  = each.key
  access_type           = each.value.access_type
  time_expires          = each.value.time_expires
  object_name           = each.value.object_name
  bucket_listing_action = each.value.bucket_listing_action
}
