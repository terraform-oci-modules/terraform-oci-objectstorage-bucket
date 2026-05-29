variable "compartment_id" {
  description = "The OCID of the compartment where the bucket will be created"
  type        = string
}

variable "kms_key_id" {
  description = "Optional KMS key OCID to use for customer-managed encryption. Leave null to use Oracle-managed encryption"
  type        = string
  default     = null
}

variable "defined_tags" {
  description = "Optional defined tags (namespace.key = value). Empty by default — pre-existing tag namespaces are required in the tenancy"
  type        = map(string)
  default     = {}
}
