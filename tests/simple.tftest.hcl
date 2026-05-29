run "creates_simple_bucket" {
  command = apply

  module {
    source = "./examples/simple"
  }

  assert {
    condition     = output.bucket_id != null
    error_message = "Bucket OCID must be returned"
  }
  assert {
    condition     = output.bucket_name != null && length(output.bucket_name) > 0
    error_message = "Bucket name must be set"
  }
  assert {
    condition     = output.namespace != null && length(output.namespace) > 0
    error_message = "Namespace must be resolved and returned"
  }
}
