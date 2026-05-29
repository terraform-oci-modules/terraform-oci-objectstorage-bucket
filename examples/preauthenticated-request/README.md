# Pre-Authenticated Requests (PARs)

A bucket with two pre-authenticated requests — the OCI equivalent of S3
presigned URLs, but as first-class server-side resources (so they belong in
Terraform, not the SDK):

| PAR name              | Scope         | Allowed action                                  |
| --------------------- | ------------- | ----------------------------------------------- |
| `bucket-listing-read` | Whole bucket  | Read any object + list objects                  |
| `upload-handoff`      | One object key | Write to `uploads/incoming.bin`                |

Both PARs expire on the same date (default `2030-01-01T00:00:00Z`, overridable
via `TF_VAR_par_expiry`). The module exposes their access URIs via the sensitive
`preauthenticated_request_uris` output.

## Usage

```bash
export TF_VAR_compartment_id="ocid1.compartment.oc1..."
terraform init
terraform apply
terraform output -json preauthenticated_request_uris
```
