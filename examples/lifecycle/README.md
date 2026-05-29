# Lifecycle — all four actions + object name filters

Bucket with a lifecycle policy that exercises every supported OCI action:

| Rule                       | Action            | Filter / target                  |
| -------------------------- | ----------------- | -------------------------------- |
| `archive-cold-data`        | ARCHIVE           | `inclusion_prefixes = ["archive/"]` |
| `ia-warm-logs`             | INFREQUENT_ACCESS | prefix `logs/` minus `*.tmp`     |
| `delete-temp-files`        | DELETE            | `inclusion_patterns = ["temp/*"]` |
| `purge-old-versions`       | DELETE            | `target = "previous-object-versions"` (1 year) |
| `abort-stale-multipart`    | ABORT             | `target = "multipart-uploads"`   |

## Usage

```bash
export TF_VAR_compartment_id="ocid1.compartment.oc1..."
terraform init
terraform apply
```
