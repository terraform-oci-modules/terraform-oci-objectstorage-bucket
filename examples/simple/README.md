# Simple — minimal private bucket

Creates a single private bucket (`access_type = "NoPublicAccess"`) with tags.

## Usage

```bash
export TF_VAR_compartment_id="ocid1.compartment.oc1..."
terraform init
terraform plan
terraform apply
```
