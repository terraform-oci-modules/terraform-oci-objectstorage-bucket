################################################################################
# Object Lifecycle Policy
#
# Maps to the AWS S3 lifecycle_rule. OCI exposes lifecycle as a dedicated
# resource (one policy per bucket holding many rules) rather than an inline
# block on the bucket.
#
# Constraint: target = "previous-object-versions" requires versioning to be
# enabled on the bucket - the OCI API rejects it otherwise.
################################################################################

resource "oci_objectstorage_object_lifecycle_policy" "this" {
  count = local.create_bucket && length(var.lifecycle_rule) > 0 ? 1 : 0

  namespace = local.namespace
  bucket    = oci_objectstorage_bucket.this[0].name

  dynamic "rules" {
    for_each = var.lifecycle_rule
    content {
      name        = rules.value.name
      action      = rules.value.action
      time_amount = rules.value.time_amount
      time_unit   = rules.value.time_unit
      is_enabled  = rules.value.is_enabled
      target      = rules.value.target

      dynamic "object_name_filter" {
        for_each = rules.value.object_name_filter != null ? [rules.value.object_name_filter] : []
        content {
          inclusion_prefixes = object_name_filter.value.inclusion_prefixes
          inclusion_patterns = object_name_filter.value.inclusion_patterns
          exclusion_patterns = object_name_filter.value.exclusion_patterns
        }
      }
    }
  }
}
