################################################################################
# Core / Control
################################################################################

variable "create_bucket" {
  description = "Controls if resources should be created (master switch - affects all resources). Maps to create_bucket in the AWS module"
  type        = bool
  default     = true
}

variable "bucket" {
  description = "Name of the bucket (maps to display_name / name in OCI). Maps to bucket in the AWS module"
  type        = string
  default     = ""
}

variable "compartment_id" {
  description = "The OCID of the compartment where the bucket and all resources will be created"
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.[a-z0-9]+\\.", var.compartment_id))
    error_message = "compartment_id must be a valid OCI OCID starting with ocid1.compartment or ocid1.tenancy."
  }
}

variable "namespace" {
  description = "The Object Storage namespace. When null (default), it is auto-resolved from the tenancy via the oci_objectstorage_namespace data source. OCI-only - no AWS equivalent"
  type        = string
  default     = null
}

################################################################################
# Bucket Configuration
################################################################################

variable "access_type" {
  description = <<-EOT
    Public access level for the bucket. Maps to the AWS public access block / canned ACL concept.
    "NoPublicAccess" - no anonymous access (default; equivalent to S3 public access block ON)
    "ObjectRead" - anonymous read of objects, with bucket listing
    "ObjectReadWithoutList" - anonymous read of objects, listing denied
  EOT
  type        = string
  default     = "NoPublicAccess"

  validation {
    condition     = contains(["NoPublicAccess", "ObjectRead", "ObjectReadWithoutList"], var.access_type)
    error_message = "access_type must be one of: NoPublicAccess, ObjectRead, ObjectReadWithoutList."
  }
}

variable "storage_tier" {
  description = <<-EOT
    Default storage tier for objects in the bucket. Maps loosely to the AWS default storage class.
    "Standard" (default) or "Archive". NOTE: this is immutable - changing it forces bucket replacement.
  EOT
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Archive"], var.storage_tier)
    error_message = "storage_tier must be one of: Standard, Archive."
  }
}

variable "versioning" {
  description = <<-EOT
    Object versioning state. Maps to the AWS versioning configuration.
    "Disabled" (default), "Enabled", or "Suspended". Note OCI uses a single string
    rather than the AWS map shape. Required to be "Enabled" when using replication.
  EOT
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled", "Suspended"], var.versioning)
    error_message = "versioning must be one of: Enabled, Disabled, Suspended."
  }
}

variable "auto_tiering" {
  description = <<-EOT
    Automatic storage tiering. Maps to AWS S3 Intelligent-Tiering.
    "Disabled" (default) or "InfrequentAccess" - automatically moves objects not
    accessed for 30+ days to the Infrequent Access tier.
  EOT
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Disabled", "InfrequentAccess"], var.auto_tiering)
    error_message = "auto_tiering must be one of: Disabled, InfrequentAccess."
  }
}

variable "object_events_enabled" {
  description = "Whether to emit OCI Events on object state changes (create/update/delete). Rough equivalent of enabling S3 event notifications; consume the events via the OCI Events service"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "OCID of the KMS master encryption key to use for the bucket. When null (default), OCI uses Oracle-managed encryption. Maps to SSE-KMS (kms_master_key_id) in AWS"
  type        = string
  default     = null
}

variable "metadata" {
  description = "Arbitrary user-defined metadata key-value pairs to store on the bucket. OCI prefixes each key with opc-meta-"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "retention_rules" {
  description = <<-EOT
    Inline retention rules - the OCI equivalent of S3 Object Lock (WORM).
    Each rule requires a duration (time_amount + time_unit). time_unit is "DAYS"
    or "YEARS". time_rule_locked is an RFC3339 timestamp after which the rule
    becomes permanently locked (the COMPLIANCE equivalent - once that time passes
    the rule can no longer be modified or deleted).
    IMPORTANT: OCI does not allow retention rules on versioning-enabled buckets.
    Set versioning = "Disabled" (default) when using retention_rules.
  EOT
  type = list(object({
    display_name     = string
    time_amount      = number
    time_unit        = string
    time_rule_locked = optional(string)
  }))
  default  = []
  nullable = false
}

variable "lifecycle_rule" {
  description = <<-EOT
    Object lifecycle rules. Maps to the AWS lifecycle_rule.
    action:    "ARCHIVE", "INFREQUENT_ACCESS", "DELETE", or "ABORT" (abort incomplete multipart uploads)
    time_unit: "DAYS" (default) or "YEARS"
    target:    "objects" (default), "multipart-uploads", or "previous-object-versions"
    object_name_filter: optional inclusion/exclusion prefixes and glob patterns
  EOT
  type = list(object({
    name        = string
    action      = string
    time_amount = number
    time_unit   = optional(string, "DAYS")
    is_enabled  = optional(bool, true)
    target      = optional(string)
    object_name_filter = optional(object({
      inclusion_prefixes = optional(list(string))
      inclusion_patterns = optional(list(string))
      exclusion_patterns = optional(list(string))
    }))
  }))
  default  = []
  nullable = false
}

variable "replication_policy" {
  description = <<-EOT
    Cross-region replication policy. Maps to the AWS replication_configuration.
    The destination bucket must already exist in destination_region_name, and the
    source bucket must have versioning = "Enabled".
  EOT
  type = object({
    name                    = string
    destination_region_name = string
    destination_bucket_name = string
  })
  default = null
}

variable "preauthenticated_requests" {
  description = <<-EOT
    Map of pre-authenticated requests (PARs) to create on the bucket. Rough
    equivalent of AWS S3 presigned URLs. Map key is the PAR name.
    access_type:           "ObjectRead", "ObjectWrite", "ObjectReadWrite",
                           "AnyObjectRead", "AnyObjectWrite", "AnyObjectReadWrite"
    time_expires:          RFC3339 expiry timestamp
    object_name:           specific object/prefix (null = bucket-level access)
    bucket_listing_action: "Deny" (default) or "ListObjects"
  EOT
  type = map(object({
    access_type           = string
    time_expires          = string
    object_name           = optional(string)
    bucket_listing_action = optional(string)
  }))
  default  = {}
  nullable = false
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "A map of freeform tags to add to all resources. Maps to tags in the AWS module"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "defined_tags" {
  description = "A map of defined tags (namespace.key = value) to add to all resources. OCI-only - no AWS equivalent"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "bucket_tags" {
  description = "Additional freeform tags applied to the bucket only (merged with var.tags)"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "bucket_defined_tags" {
  description = "Additional defined tags applied to the bucket only (merged with var.defined_tags)"
  type        = map(string)
  default     = {}
  nullable    = false
}
