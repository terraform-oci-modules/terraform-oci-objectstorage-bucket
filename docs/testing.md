# Testing

The test suite lives in `tests/` — one `.tftest.hcl` file per example. All tests run from the module root via a single `terraform test` invocation.

## Prerequisites

- Terraform >= 1.6
- OCI credentials configured — any of:
  - Environment variables (`OCI_CLI_TENANCY`, `OCI_CLI_USER`, `OCI_CLI_FINGERPRINT`, `OCI_CLI_KEY_FILE`, `OCI_CLI_REGION`)
  - A config file at `~/.oci/config`
  - Instance principal (when running from an OCI compute instance)
- A target compartment OCID

## Quick start

```bash
export TF_VAR_compartment_id="ocid1.compartment.oc1.."
terraform init
terraform test -filter=tests/simple.tftest.hcl
```

## Running all tests

```bash
export TF_VAR_compartment_id="ocid1.compartment.oc1.."
terraform init
terraform test
```

## Notes

- Tests use `command = apply` — they create and destroy **real** OCI buckets. Object Storage itself is inexpensive, but a KMS key is required for the `complete` test; reuse a pre-existing key by exporting `TF_VAR_kms_key_id` or skip that test if you do not have one.
- The `replication` test requires the destination bucket to exist in a **different** region from the source. The example uses a second `provider "oci"` alias for `us-phoenix-1`; make sure your credentials have access there or override `TF_VAR_destination_region`. OCI rejects same-region replication with a cryptic 400 error.
- The `replication` test also requires a **tenancy-level IAM policy** granting the OCI Object Storage service principal permission to replicate across regions. Without it you get a `403-ReplicationPolicyClientError`. The required policy is documented by Oracle at [OCI Replication Prerequisites](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/usingreplication.htm). Specifically, the destination tenancy must grant the source tenancy's Object Storage service access to manage objects in the destination compartment. This is a one-time setup done outside Terraform before running this test.
- Bucket names are globally unique within a namespace. The examples use static names (e.g. `ex-simple`), so a failed run that leaks a bucket must be cleaned up before re-running that test. Each example uses a distinct name, so the suite does not self-collide.
- A bucket cannot be deleted while it contains objects. None of the tests upload objects, so `terraform destroy` succeeds cleanly.
