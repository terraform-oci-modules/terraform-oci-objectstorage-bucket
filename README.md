# OCI Object Storage Bucket Terraform Module

Terraform module which creates Object Storage Bucket resources on Oracle Cloud Infrastructure (OCI).

Designed to be familiar to users of the [terraform-aws-modules/s3-bucket/aws](https://github.com/terraform-aws-modules/terraform-aws-s3-bucket) module - same variable naming conventions, same file structure, same developer experience.

## Usage

```hcl
module "bucket" {
  source  = "terraform-oci-modules/objectstorage-bucket/oci"
  version = "~> 0.1"

  bucket         = "my-bucket"
  compartment_id = var.compartment_id

  versioning            = "Enabled"
  auto_tiering          = "InfrequentAccess"
  object_events_enabled = true
  kms_key_id            = var.kms_key_id

  lifecycle_rule = [
    {
      name        = "archive-cold"
      action      = "ARCHIVE"
      time_amount = 90
      time_unit   = "DAYS"
    },
    {
      name        = "abort-stale-multipart"
      action      = "ABORT"
      time_amount = 7
      time_unit   = "DAYS"
      target      = "multipart-uploads"
    },
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

## Namespace

Every OCI Object Storage operation needs a tenancy-scoped namespace. The module
auto-resolves it via the `oci_objectstorage_namespace` data source - you do not
need to look it up or pass it. Override with `var.namespace` only if you have a
non-default namespace.

## Access Type

OCI replaces the AWS public-access-block + ACL pair with a single switch:

```hcl
access_type = "NoPublicAccess"        # default - fully private
access_type = "ObjectRead"            # anonymous read + list (public asset bucket)
access_type = "ObjectReadWithoutList" # anonymous read, no listing
```

Fine-grained per-principal access is granted through tenancy-level
`oci_identity_policy` statements, managed outside this module.

## Encryption

OCI encrypts every bucket at rest by default with Oracle-managed keys - there is
no "enable encryption" flag. Pass `kms_key_id` to use a customer-managed key
instead. SSE-C (customer-provided keys per upload) is not exposed by the
Terraform provider.

## Retention Rules (Object Lock / WORM)

OCI retention rules are inline on the bucket. Each rule requires a `display_name`
and a `duration` block (`time_amount` + `time_unit`: `"DAYS"` or `"YEARS"`).
Set `time_rule_locked` to an RFC3339 timestamp to make the rule permanent - once
that time passes the rule cannot be modified or deleted, giving the
COMPLIANCE-style guarantee AWS exposes through `default_retention.mode = "COMPLIANCE"`.

```hcl
retention_rules = [
  {
    display_name = "thirty-day-retention"
    time_amount  = 30
    time_unit    = "DAYS"
  },
  {
    display_name     = "one-year-compliance"
    time_amount      = 1
    time_unit        = "YEARS"
    time_rule_locked = "2030-01-01T00:00:00Z"  # locked - cannot be removed after this date
  },
]
```

## Replication

Cross-region replication uses a separate `oci_objectstorage_replication_policy`
resource pointing at a destination bucket that **must already exist in a different
region**. The source bucket must have `versioning = "Enabled"`.

The [`examples/replication`](examples/replication) example wires this up with a
second `provider "oci"` alias for the destination region - the standard pattern.

## Pre-Authenticated Requests (PARs)

PARs are the OCI equivalent of S3 presigned URLs, but as first-class server-side
resources (so they belong in Terraform, not the SDK). Each PAR exposes an
`access_uri`. Scope a PAR to the whole bucket (omit `object_name`) or a single
object key. See [`examples/preauthenticated-request`](examples/preauthenticated-request).

## Tags

| Variable       | OCI tag type    |
| -------------- | --------------- |
| `tags`         | `freeform_tags` |
| `defined_tags` | `defined_tags`  |

`bucket_tags` and `bucket_defined_tags` are per-resource overlays merged on top of
the global maps.

## Examples

- [simple](examples/simple) - Minimal private bucket
- [complete](examples/complete) - Versioning + KMS + auto-tiering + object events + retention + lifecycle + metadata
- [lifecycle](examples/lifecycle) - All four lifecycle actions (ARCHIVE / INFREQUENT_ACCESS / DELETE / ABORT) with prefix + glob filters
- [replication](examples/replication) - Cross-region replication via a second provider alias
- [preauthenticated-request](examples/preauthenticated-request) - Bucket-level read + object-level write PARs, exports access URIs
- [public-access](examples/public-access) - `ObjectRead` and `ObjectReadWithoutList` side by side

## Wrappers

- [wrappers](wrappers) - Terragrunt-style `for_each` wrapper for the root module

## Testing

Each example ships with a [`terraform test`](https://developer.hashicorp.com/terraform/language/tests) file that applies real OCI resources, asserts key outputs, then destroys on completion. See [docs/testing.md](docs/testing.md) for prerequisites, OCI auth setup, and how to run the tests.

## AWS to OCI feature parity

See [docs/feature_parity.md](docs/feature_parity.md) for the full comparison against
`terraform-aws-modules/s3-bucket/aws`: feature, variable and output mapping, what is not
applicable to OCI, and what is not yet implemented.

## Related Projects

### Official Oracle module

Oracle does not publish a standalone Object Storage Terraform module. Bucket
provisioning is typically done with raw `oci_objectstorage_bucket` resources
from the [`oracle/oci`](https://registry.terraform.io/providers/oracle/oci/latest) provider.

**When to use this module:**
- You are migrating from AWS and want the same variable names as `terraform-aws-modules/s3-bucket/aws`
- You want a consistent interface across AWS and OCI infrastructure
- You want lifecycle, replication, retention, and PARs wired up under one variable surface

### Disclaimer

This is an independent community module and is **not affiliated with, endorsed by, or supported by Oracle Corporation**. Oracle Cloud Infrastructure (OCI) is a trademark of Oracle Corporation. This module uses the publicly available [OCI Terraform provider](https://registry.terraform.io/providers/oracle/oci/latest) under its Mozilla Public License 2.0.

## License

[Apache 2.0](LICENSE)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_oci"></a> [oci](#provider\_oci) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [oci_objectstorage_bucket.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_bucket) | resource |
| [oci_objectstorage_object_lifecycle_policy.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_object_lifecycle_policy) | resource |
| [oci_objectstorage_preauthrequest.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_preauthrequest) | resource |
| [oci_objectstorage_replication_policy.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_replication_policy) | resource |
| [oci_objectstorage_namespace.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/objectstorage_namespace) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_type"></a> [access\_type](#input\_access\_type) | Public access level for the bucket. Maps to the AWS public access block / canned ACL concept.<br/>"NoPublicAccess" - no anonymous access (default; equivalent to S3 public access block ON)<br/>"ObjectRead" - anonymous read of objects, with bucket listing<br/>"ObjectReadWithoutList" - anonymous read of objects, listing denied | `string` | `"NoPublicAccess"` | no |
| <a name="input_auto_tiering"></a> [auto\_tiering](#input\_auto\_tiering) | Automatic storage tiering. Maps to AWS S3 Intelligent-Tiering.<br/>"Disabled" (default) or "InfrequentAccess" - automatically moves objects not<br/>accessed for 30+ days to the Infrequent Access tier. | `string` | `"Disabled"` | no |
| <a name="input_bucket"></a> [bucket](#input\_bucket) | Name of the bucket (maps to display\_name / name in OCI). Maps to bucket in the AWS module | `string` | `""` | no |
| <a name="input_bucket_defined_tags"></a> [bucket\_defined\_tags](#input\_bucket\_defined\_tags) | Additional defined tags applied to the bucket only (merged with var.defined\_tags) | `map(string)` | `{}` | no |
| <a name="input_bucket_tags"></a> [bucket\_tags](#input\_bucket\_tags) | Additional freeform tags applied to the bucket only (merged with var.tags) | `map(string)` | `{}` | no |
| <a name="input_compartment_id"></a> [compartment\_id](#input\_compartment\_id) | The OCID of the compartment where the bucket and all resources will be created | `string` | n/a | yes |
| <a name="input_create_bucket"></a> [create\_bucket](#input\_create\_bucket) | Controls if resources should be created (master switch - affects all resources). Maps to create\_bucket in the AWS module | `bool` | `true` | no |
| <a name="input_defined_tags"></a> [defined\_tags](#input\_defined\_tags) | A map of defined tags (namespace.key = value) to add to all resources. OCI-only - no AWS equivalent | `map(string)` | `{}` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | OCID of the KMS master encryption key to use for the bucket. When null (default), OCI uses Oracle-managed encryption. Maps to SSE-KMS (kms\_master\_key\_id) in AWS | `string` | `null` | no |
| <a name="input_lifecycle_rule"></a> [lifecycle\_rule](#input\_lifecycle\_rule) | Object lifecycle rules. Maps to the AWS lifecycle\_rule.<br/>action:    "ARCHIVE", "INFREQUENT\_ACCESS", "DELETE", or "ABORT" (abort incomplete multipart uploads)<br/>time\_unit: "DAYS" (default) or "YEARS"<br/>target:    "objects" (default), "multipart-uploads", or "previous-object-versions"<br/>object\_name\_filter: optional inclusion/exclusion prefixes and glob patterns | <pre>list(object({<br/>    name        = string<br/>    action      = string<br/>    time_amount = number<br/>    time_unit   = optional(string, "DAYS")<br/>    is_enabled  = optional(bool, true)<br/>    target      = optional(string)<br/>    object_name_filter = optional(object({<br/>      inclusion_prefixes = optional(list(string))<br/>      inclusion_patterns = optional(list(string))<br/>      exclusion_patterns = optional(list(string))<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Arbitrary user-defined metadata key-value pairs to store on the bucket. OCI prefixes each key with opc-meta- | `map(string)` | `{}` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Object Storage namespace. When null (default), it is auto-resolved from the tenancy via the oci\_objectstorage\_namespace data source. OCI-only - no AWS equivalent | `string` | `null` | no |
| <a name="input_object_events_enabled"></a> [object\_events\_enabled](#input\_object\_events\_enabled) | Whether to emit OCI Events on object state changes (create/update/delete). Rough equivalent of enabling S3 event notifications; consume the events via the OCI Events service | `bool` | `false` | no |
| <a name="input_preauthenticated_requests"></a> [preauthenticated\_requests](#input\_preauthenticated\_requests) | Map of pre-authenticated requests (PARs) to create on the bucket. Rough<br/>equivalent of AWS S3 presigned URLs. Map key is the PAR name.<br/>access\_type:           "ObjectRead", "ObjectWrite", "ObjectReadWrite",<br/>                       "AnyObjectRead", "AnyObjectWrite", "AnyObjectReadWrite"<br/>time\_expires:          RFC3339 expiry timestamp<br/>object\_name:           specific object/prefix (null = bucket-level access)<br/>bucket\_listing\_action: "Deny" (default) or "ListObjects" | <pre>map(object({<br/>    access_type           = string<br/>    time_expires          = string<br/>    object_name           = optional(string)<br/>    bucket_listing_action = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_replication_policy"></a> [replication\_policy](#input\_replication\_policy) | Cross-region replication policy. Maps to the AWS replication\_configuration.<br/>The destination bucket must already exist in destination\_region\_name, and the<br/>source bucket must have versioning = "Enabled". | <pre>object({<br/>    name                    = string<br/>    destination_region_name = string<br/>    destination_bucket_name = string<br/>  })</pre> | `null` | no |
| <a name="input_retention_rules"></a> [retention\_rules](#input\_retention\_rules) | Inline retention rules - the OCI equivalent of S3 Object Lock (WORM).<br/>Each rule requires a duration (time\_amount + time\_unit). time\_unit is "DAYS"<br/>or "YEARS". time\_rule\_locked is an RFC3339 timestamp after which the rule<br/>becomes permanently locked (the COMPLIANCE equivalent - once that time passes<br/>the rule can no longer be modified or deleted).<br/>IMPORTANT: OCI does not allow retention rules on versioning-enabled buckets.<br/>Set versioning = "Disabled" (default) when using retention\_rules. | <pre>list(object({<br/>    display_name     = string<br/>    time_amount      = number<br/>    time_unit        = string<br/>    time_rule_locked = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_storage_tier"></a> [storage\_tier](#input\_storage\_tier) | Default storage tier for objects in the bucket. Maps loosely to the AWS default storage class.<br/>"Standard" (default) or "Archive". NOTE: this is immutable - changing it forces bucket replacement. | `string` | `"Standard"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of freeform tags to add to all resources. Maps to tags in the AWS module | `map(string)` | `{}` | no |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | Object versioning state. Maps to the AWS versioning configuration.<br/>"Disabled" (default), "Enabled", or "Suspended". Note OCI uses a single string<br/>rather than the AWS map shape. Required to be "Enabled" when using replication. | `string` | `"Disabled"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_approximate_count"></a> [approximate\_count](#output\_approximate\_count) | The approximate number of objects in the bucket |
| <a name="output_approximate_size"></a> [approximate\_size](#output\_approximate\_size) | The approximate total size in bytes of all objects in the bucket |
| <a name="output_bucket_all_attributes"></a> [bucket\_all\_attributes](#output\_bucket\_all\_attributes) | All attributes of the created bucket (full object, auto-updating) |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | The OCID of the bucket |
| <a name="output_etag"></a> [etag](#output\_etag) | The entity tag (ETag) of the bucket |
| <a name="output_id"></a> [id](#output\_id) | The bucket identifier (the bucket name, which is the resource ID in OCI) |
| <a name="output_is_read_only"></a> [is\_read\_only](#output\_is\_read\_only) | Whether the bucket is read-only (true when it is a replication destination) |
| <a name="output_lifecycle_policy_id"></a> [lifecycle\_policy\_id](#output\_lifecycle\_policy\_id) | The ID of the object lifecycle policy. Null when no lifecycle\_rule are configured |
| <a name="output_name"></a> [name](#output\_name) | The name of the bucket |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | The Object Storage namespace the bucket lives in |
| <a name="output_preauthenticated_request_uris"></a> [preauthenticated\_request\_uris](#output\_preauthenticated\_request\_uris) | Map of PAR name to its full access URI. Sensitive - each URI grants the configured access without further credentials |
| <a name="output_replication_policy_id"></a> [replication\_policy\_id](#output\_replication\_policy\_id) | The OCID of the replication policy. Null when no replication\_policy is configured |
| <a name="output_replication_status"></a> [replication\_status](#output\_replication\_status) | The status of the replication policy (e.g. ACTIVE, CLIENT\_ERROR). Null when no replication\_policy is configured |
<!-- END_TF_DOCS -->
