module "wrapper" {
  source = "../"

  for_each = var.items

  access_type               = try(each.value.access_type, var.defaults.access_type, "NoPublicAccess")
  auto_tiering              = try(each.value.auto_tiering, var.defaults.auto_tiering, "Disabled")
  bucket                    = try(each.value.bucket, var.defaults.bucket, "")
  bucket_defined_tags       = try(each.value.bucket_defined_tags, var.defaults.bucket_defined_tags, {})
  bucket_tags               = try(each.value.bucket_tags, var.defaults.bucket_tags, {})
  compartment_id            = try(each.value.compartment_id, var.defaults.compartment_id)
  create_bucket             = try(each.value.create_bucket, var.defaults.create_bucket, true)
  defined_tags              = try(each.value.defined_tags, var.defaults.defined_tags, {})
  kms_key_id                = try(each.value.kms_key_id, var.defaults.kms_key_id, null)
  lifecycle_rule            = try(each.value.lifecycle_rule, var.defaults.lifecycle_rule, [])
  metadata                  = try(each.value.metadata, var.defaults.metadata, {})
  namespace                 = try(each.value.namespace, var.defaults.namespace, null)
  object_events_enabled     = try(each.value.object_events_enabled, var.defaults.object_events_enabled, false)
  preauthenticated_requests = try(each.value.preauthenticated_requests, var.defaults.preauthenticated_requests, {})
  replication_policy        = try(each.value.replication_policy, var.defaults.replication_policy, null)
  retention_rules           = try(each.value.retention_rules, var.defaults.retention_rules, [])
  storage_tier              = try(each.value.storage_tier, var.defaults.storage_tier, "Standard")
  tags                      = try(each.value.tags, var.defaults.tags, {})
  versioning                = try(each.value.versioning, var.defaults.versioning, "Disabled")
}
