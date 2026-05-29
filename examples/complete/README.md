# Complete — all OCI-mappable features

A bucket with versioning, auto-tiering, object events, retention rules (WORM),
a lifecycle policy covering all four action types, and metadata.

KMS-managed encryption is optional — pass `TF_VAR_kms_key_id` to use a
customer-managed key, otherwise Oracle-managed encryption is used (default).

## Usage

```bash
export TF_VAR_compartment_id="ocid1.compartment.oc1..."
# optional
export TF_VAR_kms_key_id="ocid1.key.oc1..."
terraform init
terraform apply
```
