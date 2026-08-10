variable "compartment_id" {
  description = "The OCID of the compartment where the buckets will be created"
  type        = string
}

variable "source_region" {
  description = "Region for the source bucket"
  type        = string
  default     = "us-ashburn-1"
}

variable "destination_region" {
  description = "Region for the destination bucket (must differ from source_region)"
  type        = string
  default     = "us-chicago-1"
}
