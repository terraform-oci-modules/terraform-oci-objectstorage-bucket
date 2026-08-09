# Replication — cross-region

Creates a source bucket in `us-ashburn-1` and a destination bucket in
`us-chicago-1` (override via `TF_VAR_source_region` / `TF_VAR_destination_region`),
then attaches a replication policy on the source pointing at the destination.

Two requirements OCI enforces:
- The destination bucket must already exist in the destination region — handled
  by Terraform's dependency ordering between the two module calls.
- The source bucket must have `versioning = "Enabled"`. Same applies to the
  destination if you want versioned replicas (set here).

## Usage

```bash
export TF_VAR_compartment_id="ocid1.compartment.oc1..."
terraform init
terraform apply
```
