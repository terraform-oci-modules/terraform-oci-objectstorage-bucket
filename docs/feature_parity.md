# Feature Parity: OCI Object Storage Bucket vs AWS S3 Bucket

Comparison between this module (`terraform-oci-modules/objectstorage-bucket/oci`) and the
reference AWS module (`terraform-aws-modules/s3-bucket/aws`).

The goal is not 1:1 mapping — OCI Object Storage and AWS S3 have fundamentally different
primitives — but to make the interface feel familiar to users coming from the AWS module,
while being idiomatic OCI.

**Legend:**
- ✅ Implemented
- ⬜ Not yet implemented — OCI provider supports this; module doesn't expose it yet
- N/A Not applicable to this cloud (architectural difference, not a gap)
- OCI-only No AWS equivalent — intentional addition

---

## 1. Core / Control

| Feature             | AWS             | OCI              | Status                      |
| ------------------- | --------------- | ---------------- | --------------------------- |
| Create toggle       | `create_bucket` | `create`         | ✅                           |
| Resource name       | `bucket`        | `bucket`         | ✅                           |
| Name prefix         | `bucket_prefix` | —                | N/A (OCI has no name-prefix concept) |
| Compartment scoping | —               | `compartment_id` | OCI-only                    |
| Namespace scoping   | —               | `namespace` (auto-resolved) | OCI-only         |
| Region override     | `region`        | —                | N/A (provider-level in OCI) |
| Force destroy       | `force_destroy` | —                | N/A (OCI refuses to delete a non-empty bucket — no force-empty flag) |
| Expected bucket owner | `expected_bucket_owner` | —      | N/A                         |

---

## 2. Public Access

| Feature                     | AWS                                  | OCI                                          | Status |
| --------------------------- | ------------------------------------ | -------------------------------------------- | ------ |
| Public access block         | `attach_public_policy`, `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets` | `access_type = "NoPublicAccess"` (default) | ✅ (see note below) |
| Public read of objects      | canned ACL `public-read`             | `access_type = "ObjectRead"`                 | ✅      |
| Public read without listing | canned ACL `public-read` (custom)    | `access_type = "ObjectReadWithoutList"`      | ✅      |
| Object ownership controls   | `aws_s3_bucket_ownership_controls`   | —                                            | N/A    |
| Canned ACL                  | `acl`                                | —                                            | N/A    |
| Granular ACL grants         | `grant`, `owner`                     | —                                            | N/A    |

> **Why most ACL/PAB controls map to a single `access_type`**: OCI does not have S3-style ACLs.
> All cross-tenant/anonymous access is governed by the bucket's `access_type` plus tenancy-level
> IAM policies. Fine-grained per-principal grants are expressed through `oci_identity_policy`
> statements (out of scope for this module).

---

## 3. Versioning

| Feature              | AWS                                   | OCI                  | Status |
| -------------------- | ------------------------------------- | -------------------- | ------ |
| Object versioning    | `versioning.status` (map)             | `versioning` (string) | ✅ (see note below) |
| MFA delete           | `versioning.mfa_delete` / `mfa`       | —                    | N/A (OCI has no MFA delete concept) |

> **Shape difference**: AWS's `versioning` variable is a map with `status` and `mfa_delete` keys.
> OCI exposes a single string ("Enabled" / "Disabled" / "Suspended"). The OCI module uses the
> simpler string for ergonomics; the AWS-style map can be folded in via a future variable type if needed.

---

## 4. Encryption

| Feature                       | AWS                                                       | OCI                | Status                                            |
| ----------------------------- | --------------------------------------------------------- | ------------------ | ------------------------------------------------- |
| Default encryption (Oracle/AWS-managed) | Always on (SSE-S3 / aws:kms with AWS-managed key) | Always on (Oracle-managed) | ✅ (always on, no opt-in) |
| Customer KMS key              | `server_side_encryption_configuration.kms_master_key_id`  | `kms_key_id`       | ✅                                                 |
| Bucket key                    | `bucket_key_enabled`                                      | —                  | N/A (OCI does not expose a per-bucket key indirection) |
| Algorithm selection           | `sse_algorithm` (AES256 / aws:kms)                        | —                  | N/A (OCI selects algorithm based on key choice)   |
| Blocked encryption types      | `blocked_encryption_types`                                | —                  | N/A                                               |
| SSE-C (customer-provided key) | inline at PUT object                                      | —                  | N/A (not exposed in Terraform provider)           |

---

## 5. Storage Tier / Auto-tiering

| Feature              | AWS                                              | OCI                                          | Status |
| -------------------- | ------------------------------------------------ | -------------------------------------------- | ------ |
| Default storage class | (inferred from lifecycle / object PUT)          | `storage_tier` ("Standard" / "Archive")      | OCI-only ✅ (immutable — changing forces replacement) |
| Intelligent tiering  | `intelligent_tiering` (configurations + filters) | `auto_tiering` ("Disabled" / "InfrequentAccess") | ✅ (see note below) |
| Per-config filters / tiers | full filter, archive/deep-archive tiers     | —                                            | N/A (OCI auto-tiering is bucket-wide, 30-day threshold) |

> **Auto-tiering granularity**: AWS Intelligent-Tiering supports multiple per-prefix configurations
> with custom archive thresholds. OCI auto-tiering is a single bucket-wide switch — objects unused
> for 30+ days move to the Infrequent Access tier.

---

## 6. Lifecycle

| Feature                | AWS                                            | OCI                                                  | Status |
| ---------------------- | ---------------------------------------------- | ---------------------------------------------------- | ------ |
| Lifecycle rules        | `lifecycle_rule` (list)                        | `lifecycle_rules` (list) → `oci_objectstorage_object_lifecycle_policy` | ✅ |
| Expiration / transition by age | `expiration.days`, `transition.days`   | `time_amount` + `time_unit` ("DAYS" / "YEARS")       | ✅      |
| Transition to archive / IA | `transition.storage_class`                 | `action` ("ARCHIVE" / "INFREQUENT_ACCESS")           | ✅      |
| Delete                 | `expiration` (no transition target)            | `action = "DELETE"`                                  | ✅      |
| Abort incomplete multipart uploads | `abort_incomplete_multipart_upload_days` | `action = "ABORT"`                          | ✅      |
| Previous-version handling | `noncurrent_version_*`                      | `target = "previous-object-versions"` (requires versioning enabled) | ✅ (see note below) |
| Prefix filter          | `filter.prefix`                                | `object_name_filter.inclusion_prefixes`              | ✅      |
| Pattern (glob) include / exclude | filter.tag / object_size_*           | `object_name_filter.inclusion_patterns` / `exclusion_patterns` | ✅ (different shape — glob patterns instead of tags / sizes) |
| Tag-based filtering    | `filter.tag` / `filter.and.tags`               | —                                                    | N/A (OCI lifecycle filters by name only) |

> **Previous-version target**: OCI enforces that `target = "previous-object-versions"` requires
> versioning to be enabled on the bucket at the API level. Pair this rule with `versioning = "Enabled"`.
> See `examples/lifecycle` for the full demonstration including this rule.
| Object size filter     | `filter.object_size_greater_than` / `_less_than` | —                                                  | N/A    |
| Expired-delete-marker  | `expiration.expired_object_delete_marker`      | —                                                    | N/A    |
| Date-based trigger     | `expiration.date`, `transition.date`           | —                                                    | N/A (OCI uses age in DAYS / YEARS only) |
| Default minimum object size | `transition_default_minimum_object_size`  | —                                                    | N/A    |

---

## 7. Object Lock / Retention

| Feature                    | AWS                                  | OCI                                       | Status                       |
| -------------------------- | ------------------------------------ | ----------------------------------------- | ---------------------------- |
| Object Lock (WORM)         | `object_lock_enabled` + `object_lock_configuration` | `retention_rules` (inline)         | ✅                            |
| Retention duration         | `default_retention.days` / `.years`  | `duration.time_amount` + `time_unit`      | ✅                            |
| Retention mode             | `default_retention.mode` (GOVERNANCE / COMPLIANCE) | —                           | N/A (OCI uses `time_rule_locked` instead — see note) |
| Versioning + retention     | Both allowed together in AWS          | Mutually exclusive in OCI — a `check` block guards against this at plan time | N/A (OCI API constraint) |
| Locked rule timestamp      | —                                    | `time_rule_locked` (RFC3339)              | OCI-only                     |
| Legal hold (indefinite)    | per-object legal hold (separate API) | —                                         | N/A (OCI retention rules always require a duration — the API rejects rules without one) |
| Token                      | `object_lock_configuration.token`    | —                                         | N/A                          |

> **GOVERNANCE vs COMPLIANCE vs OCI locked-rule**: AWS distinguishes GOVERNANCE (privileged
> override) from COMPLIANCE (no override). OCI achieves the COMPLIANCE-style guarantee by setting
> `time_rule_locked` to a past or near-future RFC3339 timestamp — once that time passes the rule
> can no longer be modified or deleted. Without `time_rule_locked` the rule behaves like
> GOVERNANCE (admins can edit it).

---

## 8. Replication

| Feature                       | AWS                                               | OCI                                                   | Status |
| ----------------------------- | ------------------------------------------------- | ----------------------------------------------------- | ------ |
| Cross-region replication      | `replication_configuration` → `aws_s3_bucket_replication_configuration` | `replication_policy` → `oci_objectstorage_replication_policy` | ✅ (single rule per policy in OCI) |
| Destination bucket / region   | `destination.bucket`, AWS region in ARN           | `destination_bucket_name` + `destination_region_name` | ✅      |
| Source versioning requirement | required                                          | required                                              | ✅ (both — must set `versioning = "Enabled"`) |
| Per-rule filter / priority    | `rule.filter`, `rule.priority`                    | —                                                     | N/A (OCI replication is bucket-wide) |
| Cross-account / role          | `role`, `destination.account`, `destination.access_control_translation` | —                            | N/A (OCI uses IAM policy + namespace-level grants) |
| Delete marker replication     | `delete_marker_replication`                       | —                                                     | N/A    |
| Existing-object replication   | `existing_object_replication`                     | —                                                     | N/A    |
| Replication time / metrics    | `replication_time`, `metrics`                     | —                                                     | N/A    |
| Replica KMS / SSE selection   | `destination.encryption_configuration`, `source_selection_criteria.sse_kms_encrypted_objects` | — | N/A |

---

## 9. Pre-Authenticated Requests

| Feature                | AWS                                          | OCI                                  | Status   |
| ---------------------- | -------------------------------------------- | ------------------------------------ | -------- |
| Time-limited access URL | Presigned URLs (per-call SDK API; not in TF) | `preauthenticated_requests` → `oci_objectstorage_preauthrequest` | OCI-only ✅ |
| Multiple PARs per bucket | —                                          | `for_each` map                       | ✅        |
| Bucket-level vs object-level scope | —                                  | `object_name` null vs set            | ✅        |
| Bucket listing toggle  | —                                            | `bucket_listing_action`              | ✅        |

> **Why this is OCI-only**: AWS presigned URLs are minted by the SDK at request time using
> session credentials — they are not Terraform resources. OCI PARs are first-class server-side
> objects with their own lifecycle, so they belong in the module.

---

## 10. Notifications / Events

| Feature                | AWS                                                                              | OCI                                  | Status        |
| ---------------------- | -------------------------------------------------------------------------------- | ------------------------------------ | ------------- |
| Emit events on object changes | `aws_s3_bucket_notification` per destination (Lambda, SQS, SNS, EventBridge) | `object_events_enabled` (bool)       | ✅ (partial — see note) |
| Event filters / destinations | per-destination filter (prefix/suffix), explicit target ARNs               | —                                    | N/A (configured via OCI Events Service rules — out of scope) |

> **Scope**: This module only toggles whether the bucket emits events to the OCI Events Service.
> Building event rules that route to OCI Functions / Streams / Notifications belongs to a
> separate `oci_events_rule` configuration outside this module.

---

## 11. Logging / Metrics / Analytics / Inventory

| Feature                       | AWS                                                                      | OCI | Status |
| ----------------------------- | ------------------------------------------------------------------------ | --- | ------ |
| Server access logging         | `logging`, `aws_s3_bucket_logging`                                       | —   | N/A (OCI captures bucket activity in audit + service logs, not per-bucket) |
| CloudWatch metrics            | `aws_s3_bucket_metric`                                                   | —   | N/A (OCI bucket metrics live in OCI Monitoring service)        |
| S3 Inventory                  | `inventory_configuration`, `attach_inventory_destination_policy`         | —   | N/A    |
| S3 Storage Class Analysis     | `analytics_configuration`, `attach_analytics_destination_policy`         | —   | N/A    |
| Storage Lens                  | —                                                                        | —   | N/A    |

---

## 12. Performance / Transfer

| Feature              | AWS                                            | OCI | Status |
| -------------------- | ---------------------------------------------- | --- | ------ |
| Transfer Acceleration | `acceleration_status`                         | —   | N/A (no acceleration tier in OCI) |
| Request Payer        | `request_payer`                                | —   | N/A    |
| CORS                 | `cors_rule`, `aws_s3_bucket_cors_configuration` | —  | N/A (OCI Object Storage does not expose per-bucket CORS rules) |
| Website hosting      | `website`, `aws_s3_bucket_website_configuration` | — | N/A (OCI requires API Gateway + Object Storage as a workaround) |

---

## 13. Bucket Types

| Feature                       | AWS                       | OCI | Status |
| ----------------------------- | ------------------------- | --- | ------ |
| S3 Express One Zone           | `is_directory_bucket`, `aws_s3_directory_bucket` | — | N/A (no single-AZ low-latency tier in OCI Object Storage) |
| S3 Tables (Iceberg)           | `metadata_configuration`, `aws_s3_bucket_metadata_configuration` | — | N/A (OCI Object Storage is object-only) |

---

## 14. Bucket Policies (IAM)

| Feature                         | AWS                                          | OCI | Status |
| ------------------------------- | -------------------------------------------- | --- | ------ |
| Resource-based policy           | `policy`, `aws_s3_bucket_policy`             | —   | N/A (OCI uses tenancy-level `oci_identity_policy` statements managed outside this module — see note below) |
| Pre-built ELB / ALB / NLB log delivery | `attach_elb_log_delivery_policy`, `attach_lb_log_delivery_policy` | — | N/A    |
| Pre-built access-log delivery   | `attach_access_log_delivery_policy`          | —   | N/A    |
| Pre-built CloudTrail / WAF policies | `attach_cloudtrail_log_delivery_policy`, `attach_waf_log_delivery_policy` | — | N/A |
| Pre-built TLS / insecure-transport policies | `attach_require_latest_tls_policy`, `attach_deny_insecure_transport_policy` | — | N/A (OCI Object Storage enforces TLS at the service edge) |
| Pre-built encryption-enforcement policies | `attach_deny_unencrypted_object_uploads`, `attach_deny_incorrect_encryption_headers`, `attach_deny_ssec_encrypted_object_uploads`, `attach_deny_incorrect_kms_key_sse` | — | N/A (OCI buckets are encrypted by default) |
| Inventory / analytics destination policies | `attach_inventory_destination_policy`, `attach_analytics_destination_policy` | — | N/A |

> **Why all `attach_*_policy` rows are N/A**: AWS S3 bucket policies are inline JSON attached
> directly to the bucket. OCI grants access through tenancy-level `oci_identity_policy`
> statements (e.g. "Allow group X to manage objects in compartment Y") that reference the
> bucket from outside. Building those is a separate IAM concern, intentionally left out of
> this module to keep its surface focused on the bucket itself.

---

## 15. Tags

| Feature           | AWS    | OCI                  | Status |
| ----------------- | ------ | -------------------- | ------ |
| Freeform tags     | `tags` | `tags`               | ✅ Identical |
| Defined tags      | —      | `defined_tags`       | OCI-only |
| Bucket-only tags  | —      | `bucket_tags` / `bucket_defined_tags` | OCI-only (per-resource merge layer) |

| Variable       | OCI tag type    |
| -------------- | --------------- |
| `tags`         | `freeform_tags` |
| `defined_tags` | `defined_tags`  |

---

## 16. Wrappers

| Wrapper             | AWS         | OCI         | Status |
| ------------------- | ----------- | ----------- | ------ |
| Root module wrapper | `wrappers/` | `wrappers/` | ✅      |
| Object submodule wrapper | `wrappers/object/` | — | N/A (no objects submodule in this OCI module — out of scope) |
| Notification submodule wrapper | `wrappers/notification/` | — | N/A (OCI Events Service rules are out of scope) |
| Table-bucket submodule wrapper | `wrappers/table-bucket/` | — | N/A (S3 Tables has no OCI equivalent) |

---

## Variables — Matched

| AWS                                              | OCI                          | Notes                                          |
| ------------------------------------------------ | ---------------------------- | ---------------------------------------------- |
| `create_bucket`                                  | `create`                     | Master toggle                                  |
| `bucket`                                         | `bucket`                     | Bucket name                                    |
| `versioning.status`                              | `versioning`                 | String instead of map                          |
| `server_side_encryption_configuration.kms_master_key_id` | `kms_key_id`         | SSE-KMS key                                    |
| `intelligent_tiering`                            | `auto_tiering`               | Bucket-wide switch                             |
| `object_lock_configuration.rule.default_retention` | `retention_rules`          | List of inline retention rules                 |
| `lifecycle_rule`                                 | `lifecycle_rules`            | Separate policy resource                       |
| `replication_configuration`                      | `replication_policy`         | Single rule, cross-region                      |
| `tags`                                           | `tags`                       | Identical                                      |

---

## Variables — AWS only (no OCI equivalent)

| AWS Variable                                                                                                                                                                                                                                                | Reason not in OCI |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| `bucket_prefix`, `bucket_namespace`                                                                                                                                                                                                                       | OCI has no name-prefix concept; namespace is tenancy-derived |
| `force_destroy`, `expected_bucket_owner`                                                                                                                                                                                                                  | No force-empty in OCI; ownership controlled via IAM         |
| `is_directory_bucket`, `data_redundancy`, `type`, `availability_zone_id`, `location_type`                                                                                                                                                                 | No S3 Express equivalent in OCI                              |
| `acl`, `grant`, `owner`, `control_object_ownership`, `object_ownership`                                                                                                                                                                                   | No ACLs in OCI                                               |
| `attach_public_policy`, `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`, `skip_destroy_public_access_block`                                                                                                   | Single `access_type` covers this in OCI                      |
| `attach_policy`, `policy`, `attach_elb_log_delivery_policy`, `attach_lb_log_delivery_policy`, `attach_access_log_delivery_policy`, `attach_cloudtrail_log_delivery_policy`, `attach_waf_log_delivery_policy`, `attach_require_latest_tls_policy`, `attach_deny_insecure_transport_policy`, `attach_deny_unencrypted_object_uploads`, `attach_deny_ssec_encrypted_object_uploads`, `attach_deny_incorrect_encryption_headers`, `attach_deny_incorrect_kms_key_sse`, `attach_inventory_destination_policy`, `attach_analytics_destination_policy`, `allowed_kms_key_arn`, `access_log_delivery_policy_source_buckets`, `access_log_delivery_policy_source_accounts`, `access_log_delivery_policy_source_organizations`, `lb_log_delivery_policy_source_organizations` | All bucket-policy variants — OCI uses tenancy-level `oci_identity_policy` outside this module |
| `acceleration_status`, `request_payer`                                                                                                                                                                                                                    | No acceleration / requester-pays in OCI                      |
| `cors_rule`                                                                                                                                                                                                                                               | OCI Object Storage has no per-bucket CORS                    |
| `website`                                                                                                                                                                                                                                                 | No native static website hosting in OCI Object Storage       |
| `logging`                                                                                                                                                                                                                                                 | OCI bucket logs flow through OCI audit + service logs        |
| `metric_configuration`, `inventory_configuration`, `analytics_configuration`, `inventory_self_source_destination`, `inventory_source_account_id`, `inventory_source_bucket_arn`, `analytics_self_source_destination`, `analytics_source_account_id`, `analytics_source_bucket_arn` | All metrics / inventory / analytics — OCI surfaces these via OCI Monitoring service |
| `transition_default_minimum_object_size`                                                                                                                                                                                                                  | OCI lifecycle has no equivalent flag                         |
| `create_metadata_configuration`, `metadata_inventory_table_configuration_state`, `metadata_encryption_configuration`, `metadata_journal_table_record_expiration_days`, `metadata_journal_table_record_expiration`                                         | S3 Tables (Iceberg) has no OCI equivalent                    |
| `object_lock_enabled`                                                                                                                                                                                                                                     | OCI retention rules are inline; no separate enable flag      |
| `region`                                                                                                                                                                                                                                                  | Provider-level in OCI                                        |
| `putin_khuylo`                                                                                                                                                                                                                                            | Out of scope                                                 |

---

## Variables — OCI only (no AWS equivalent)

| OCI Variable               | What it does                                                                |
| -------------------------- | --------------------------------------------------------------------------- |
| `compartment_id`           | Required OCI compartment scoping                                            |
| `namespace`                | Object Storage namespace (auto-resolved when null)                          |
| `access_type`              | Single switch for anonymous access level                                    |
| `storage_tier`             | Default storage tier (Standard / Archive), immutable                        |
| `auto_tiering`             | Bucket-wide auto-tiering toggle                                             |
| `object_events_enabled`    | Toggle emission of events to OCI Events Service                             |
| `metadata`                 | Arbitrary key-value metadata stored on the bucket                           |
| `retention_rules`          | Inline WORM rules with optional `time_rule_locked` for COMPLIANCE behaviour |
| `preauthenticated_requests` | First-class PAR resources (S3 presigned URLs are SDK-side, not in TF)      |
| `defined_tags`             | OCI tag namespace system                                                    |
| `bucket_tags` / `bucket_defined_tags` | Per-resource tag merge layer                                     |

### OCI-only — not yet implemented

| OCI Provider Attribute | What it does | Status |
| ---------------------- | ------------ | ------ |
| `oci_objectstorage_private_endpoint` | Private endpoint for VCN-restricted access to Object Storage (verify provider support at implementation time) | ⬜ deferred |

---

## Outputs — Matched

| AWS                                            | OCI                       | Notes                                  |
| ---------------------------------------------- | ------------------------- | -------------------------------------- |
| `s3_bucket_id`                                 | `id`                      | Bucket name (resource ID in OCI)       |
| `s3_bucket_arn`                                | `bucket_id`               | OCI uses an OCID instead of an ARN     |
| `s3_bucket_region`                             | —                         | Region is provider-level in OCI        |
| `s3_bucket_bucket_domain_name`                 | —                         | OCI buckets are addressed by namespace + name, not domain |
| `s3_bucket_lifecycle_configuration_rules`      | `lifecycle_policy_id`     | Policy ID only (rules are in state)    |
| `aws_s3_bucket_versioning_status`              | `bucket_all_attributes.versioning` | Available via the all_attributes object |
| `s3_bucket_tags`                               | `bucket_all_attributes.freeform_tags` | Same — via the all_attributes object |

---

## Outputs — AWS only

| AWS Output                                                                       | Reason not in OCI |
| -------------------------------------------------------------------------------- | ----------------- |
| `s3_bucket_arn`, `s3_bucket_bucket_domain_name`, `s3_bucket_bucket_regional_domain_name`, `s3_bucket_hosted_zone_id`, `s3_bucket_website_endpoint`, `s3_bucket_website_domain` | No AWS-style addressing in OCI |
| `s3_directory_bucket_name`, `s3_directory_bucket_arn`                            | No S3 Express equivalent |
| `s3_bucket_policy`                                                               | No bucket-attached policies in OCI |

---

## Outputs — OCI only

| OCI Output                       | What it exposes                                                  |
| -------------------------------- | ---------------------------------------------------------------- |
| `namespace`                      | The Object Storage namespace the bucket lives in                 |
| `bucket_id`                      | The bucket's OCID (separate from the resource ID, which is the name) |
| `etag`                           | Bucket entity tag                                                |
| `approximate_count`, `approximate_size` | Approximate object count and total size in bytes          |
| `is_read_only`                   | True when the bucket is a replication destination                |
| `bucket_all_attributes`          | Full `oci_objectstorage_bucket` object (auto-updating)           |
| `lifecycle_policy_id`            | Lifecycle policy resource ID                                     |
| `replication_policy_id`, `replication_status` | Replication policy OCID + current status            |
| `preauthenticated_request_uris`  | Map of PAR name → access URI (sensitive)                         |

---

## Examples

### AWS examples

| Example                | What it covers                                                                                       |
| ---------------------- | ---------------------------------------------------------------------------------------------------- |
| `complete`             | Versioning, KMS encryption, lifecycle rules, object lock, CORS, replication, bucket policies, ACL grants, CloudFront logging, inventory, analytics, metrics |
| `account-public-access` | Account-level S3 public access block settings                                                       |
| `directory-bucket`     | S3 Express One Zone bucket                                                                           |
| `notification`         | Event notifications to Lambda / SNS / SQS / EventBridge                                              |
| `object`               | S3 object upload with metadata / storage class / encryption / ACL                                    |
| `s3-analytics`         | Storage Class Analysis configuration                                                                 |
| `s3-inventory`         | S3 Inventory reports                                                                                 |
| `s3-replication`       | Cross-region replication with destination KMS                                                        |
| `table-bucket`         | S3 Tables (Apache Iceberg)                                                                           |

### OCI examples

| Example                     | What it covers                                                                                                       |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `simple`                    | Minimal private bucket (`NoPublicAccess`), tags only                                                                  |
| `complete`                  | Versioning + KMS + auto_tiering + object_events + retention rules + lifecycle rules + metadata + defined_tags        |
| `lifecycle`                 | ARCHIVE / INFREQUENT_ACCESS / DELETE / ABORT rules with prefix and glob filters                                      |
| `replication`               | Cross-region replication. Uses a second `provider "oci"` alias for the destination region and creates the destination bucket first |
| `preauthenticated-request`  | Bucket plus PARs (bucket-level read, object-level write), exports `access_uri`                                       |
| `public-access`             | `access_type = "ObjectRead"` / `"ObjectReadWithoutList"` — the OCI analogue of AWS `account-public-access`           |

### Example gap analysis

#### OCI missing vs AWS

| AWS Example / Scenario                  | OCI Status      | Notes                                                                  |
| --------------------------------------- | --------------- | ---------------------------------------------------------------------- |
| `notification`                          | Not implemented | OCI equivalent uses the Events Service + `oci_events_rule` (separate module / future) |
| `object`                                | Not implemented | OCI `oci_objectstorage_object` is intentionally out of scope (no objects submodule) |
| `s3-inventory`, `s3-analytics`          | N/A             | Surfaced via OCI Monitoring, not the bucket resource                   |
| `directory-bucket`, `table-bucket`      | N/A             | No OCI equivalent                                                      |

#### AWS missing vs OCI

| OCI Example / Scenario                | Notes                                                                |
| ------------------------------------- | -------------------------------------------------------------------- |
| `simple` — minimal standalone example | AWS `complete` is the starting point; no dedicated minimal example   |
| `preauthenticated-request`            | No AWS Terraform analogue — presigned URLs are SDK-side               |
| `public-access` — single-axis switch  | AWS spreads this across multiple block/ACL flags                     |

---

## Summary

**Good parity:** core bucket creation, versioning, KMS encryption, lifecycle rules
(archive / IA / delete / abort multipart), retention rules (object lock),
cross-region replication, tags.

**True AWS-only (confirmed N/A):** ACLs and ownership controls, public access block flags
(folded into `access_type`), all `attach_*_policy` document helpers (OCI uses
tenancy-level IAM policies), website hosting, CORS, transfer acceleration, request payer,
S3 Express One Zone, S3 Tables, S3 Inventory / Analytics / Metrics / Storage Lens,
MFA delete, bucket key, blocked encryption types.

**OCI advantages in this module:** pre-authenticated requests (no AWS Terraform analogue),
auto-tiering with a single switch, locked retention rules via `time_rule_locked`,
defined-tag namespace system, compartment scoping.

### Implementation backlog

#### AWS parity gaps — OCI provider supports these, module does not yet expose them

_None — all OCI-mappable AWS features in scope are implemented._

#### OCI-native features — no AWS equivalent, not yet in the module

- `oci_objectstorage_private_endpoint` — private VCN-restricted access (verify provider support)

#### Examples

- `notification` / OCI Events Service rule example — once an `oci_events_rule` submodule exists
- `multiple` / wrapper example — showcase `for_each` across buckets via `wrappers/`
