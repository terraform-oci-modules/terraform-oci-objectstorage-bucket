output "bucket_id" {
  description = "The OCID of the bucket"
  value       = module.bucket.bucket_id
}

output "bucket_name" {
  description = "The name of the bucket"
  value       = module.bucket.name
}

output "namespace" {
  description = "The Object Storage namespace"
  value       = module.bucket.namespace
}

output "lifecycle_policy_id" {
  description = "The ID of the lifecycle policy"
  value       = module.bucket.lifecycle_policy_id
}

output "bucket_all_attributes" {
  description = "Full bucket attribute object (for downstream consumers)"
  value       = module.bucket.bucket_all_attributes
}
