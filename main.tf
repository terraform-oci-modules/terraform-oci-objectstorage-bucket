locals {
  create_bucket = var.create_bucket

  # Object Storage namespace is required on every bucket/policy resource.
  # Auto-resolve it from the tenancy when the caller does not pass one.
  namespace = var.namespace != null ? var.namespace : data.oci_objectstorage_namespace.this.namespace

  # Freeform tag merge: Name key, global tags, then bucket-specific tags.
  bucket_freeform_tags = merge({ "Name" = var.bucket }, var.tags, var.bucket_tags)
  bucket_defined_tags  = merge(var.defined_tags, var.bucket_defined_tags)

  # Canonical bucket reference for outputs.
  bucket = try(oci_objectstorage_bucket.this[0], null)
}

################################################################################
# Data Sources
################################################################################

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_id
}

################################################################################
# Guards - some OCI Object Storage argument combinations are rejected by the API
# at apply time with cryptic 400 errors. Catch them at plan time instead so the
# message is actionable.
################################################################################

check "auto_tiering_ia_lifecycle_conflict" {
  assert {
    condition     = !(var.auto_tiering == "InfrequentAccess" && anytrue([for r in var.lifecycle_rule : r.action == "INFREQUENT_ACCESS"]))
    error_message = "When auto_tiering = \"InfrequentAccess\", lifecycle rules with action = \"INFREQUENT_ACCESS\" are rejected by the OCI API. Remove the INFREQUENT_ACCESS lifecycle rule."
  }
}

check "retention_rules_versioning_conflict" {
  assert {
    condition     = !(length(var.retention_rules) > 0 && var.versioning != "Disabled")
    error_message = "OCI does not allow retention_rules on a versioning-enabled bucket. Set versioning = \"Disabled\" (default) when using retention_rules."
  }
}

################################################################################
# Bucket
################################################################################

resource "oci_objectstorage_bucket" "this" {
  count = local.create_bucket ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = local.namespace
  name           = var.bucket

  access_type           = var.access_type
  storage_tier          = var.storage_tier
  versioning            = var.versioning
  auto_tiering          = var.auto_tiering
  object_events_enabled = var.object_events_enabled
  kms_key_id            = var.kms_key_id
  metadata              = var.metadata

  # Inline retention rules - the OCI equivalent of S3 Object Lock (WORM).
  # duration is always required; the OCI API rejects requests without it.
  dynamic "retention_rules" {
    for_each = var.retention_rules
    content {
      display_name = retention_rules.value.display_name

      duration {
        time_amount = retention_rules.value.time_amount
        time_unit   = retention_rules.value.time_unit
      }

      time_rule_locked = retention_rules.value.time_rule_locked
    }
  }

  freeform_tags = local.bucket_freeform_tags
  defined_tags  = local.bucket_defined_tags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}
