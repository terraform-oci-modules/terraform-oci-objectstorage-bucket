output "bucket_id" {
  description = "OCID of the bucket"
  value       = module.bucket.bucket_id
}

output "bucket_name" {
  description = "Name of the bucket"
  value       = module.bucket.name
}

output "preauthenticated_request_uris" {
  description = "Map of PAR name to access URI (sensitive - each URI grants access without further credentials)"
  value       = module.bucket.preauthenticated_request_uris
  sensitive   = true
}
