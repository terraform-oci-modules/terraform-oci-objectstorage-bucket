output "public_read_bucket_id" {
  description = "OCID of the ObjectRead bucket"
  value       = module.public_read.bucket_id
}

output "public_read_no_list_bucket_id" {
  description = "OCID of the ObjectReadWithoutList bucket"
  value       = module.public_read_no_list.bucket_id
}
