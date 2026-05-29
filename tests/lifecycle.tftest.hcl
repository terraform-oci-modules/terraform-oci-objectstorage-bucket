run "creates_lifecycle_policy" {
  command = apply

  module {
    source = "./examples/lifecycle"
  }

  assert {
    condition     = output.bucket_id != null
    error_message = "Bucket must be created"
  }
  assert {
    condition     = output.lifecycle_policy_id != null
    error_message = "Lifecycle policy must be created and ID exposed"
  }
}
