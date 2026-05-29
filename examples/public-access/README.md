# Public Access — anonymous read access levels

OCI Object Storage exposes anonymous access via a single `access_type` switch
instead of the AWS public-access-block + ACL pair. This example creates two
buckets showing the public levels side by side:

| Module                    | `access_type`            | Behaviour                                              |
| ------------------------- | ------------------------ | ------------------------------------------------------ |
| `public_read`             | `ObjectRead`             | Anonymous GET + LIST — closest to an AWS public website bucket |
| `public_read_no_list`     | `ObjectReadWithoutList`  | Anonymous GET, LIST denied — asset bucket, no enumeration       |

The `NoPublicAccess` default (private bucket — equivalent of AWS public access
block ON) is exercised by `examples/simple`.

## Usage

```bash
export TF_VAR_compartment_id="ocid1.compartment.oc1..."
terraform init
terraform apply
```
