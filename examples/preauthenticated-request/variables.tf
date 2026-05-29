variable "compartment_id" {
  description = "The OCID of the compartment where the bucket will be created"
  type        = string
}

variable "par_expiry" {
  description = "RFC3339 expiry timestamp shared by the two PARs in this example. Override per-environment as needed"
  type        = string
  default     = "2030-01-01T00:00:00Z"
}
