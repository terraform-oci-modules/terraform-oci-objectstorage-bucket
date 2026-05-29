################################################################################
# Bucket
################################################################################

output "id" {
  description = "The bucket identifier (the bucket name, which is the resource ID in OCI)"
  value       = try(local.bucket.id, null)
}

output "bucket_id" {
  description = "The OCID of the bucket"
  value       = try(local.bucket.bucket_id, null)
}

output "name" {
  description = "The name of the bucket"
  value       = try(local.bucket.name, null)
}

output "namespace" {
  description = "The Object Storage namespace the bucket lives in"
  value       = local.create ? local.namespace : null
}

output "etag" {
  description = "The entity tag (ETag) of the bucket"
  value       = try(local.bucket.etag, null)
}

output "approximate_count" {
  description = "The approximate number of objects in the bucket"
  value       = try(local.bucket.approximate_count, null)
}

output "approximate_size" {
  description = "The approximate total size in bytes of all objects in the bucket"
  value       = try(local.bucket.approximate_size, null)
}

output "is_read_only" {
  description = "Whether the bucket is read-only (true when it is a replication destination)"
  value       = try(local.bucket.is_read_only, null)
}

output "bucket_all_attributes" {
  description = "All attributes of the created bucket (full object, auto-updating)"
  value       = local.bucket
}

################################################################################
# Lifecycle / Replication
################################################################################

output "lifecycle_policy_id" {
  description = "The ID of the object lifecycle policy. Null when no lifecycle_rules are configured"
  value       = try(oci_objectstorage_object_lifecycle_policy.this[0].id, null)
}

output "replication_policy_id" {
  description = "The OCID of the replication policy. Null when no replication_policy is configured"
  value       = try(oci_objectstorage_replication_policy.this[0].id, null)
}

output "replication_status" {
  description = "The status of the replication policy (e.g. ACTIVE, CLIENT_ERROR). Null when no replication_policy is configured"
  value       = try(oci_objectstorage_replication_policy.this[0].status, null)
}

################################################################################
# Pre-Authenticated Requests
################################################################################

output "preauthenticated_request_uris" {
  description = "Map of PAR name to its full access URI. Sensitive — each URI grants the configured access without further credentials"
  value       = { for k, v in oci_objectstorage_preauthrequest.this : k => v.access_uri }
  sensitive   = true
}
