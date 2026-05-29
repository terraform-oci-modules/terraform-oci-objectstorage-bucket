output "source_bucket_id" {
  description = "OCID of the source bucket"
  value       = module.source_bucket.bucket_id
}

output "destination_bucket_id" {
  description = "OCID of the destination bucket"
  value       = module.destination_bucket.bucket_id
}

output "replication_policy_id" {
  description = "OCID of the replication policy"
  value       = module.source_bucket.replication_policy_id
}

output "replication_status" {
  description = "Status of the replication policy (e.g. ACTIVE, CLIENT_ERROR)"
  value       = module.source_bucket.replication_status
}
