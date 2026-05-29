run "creates_complete_bucket" {
  command = apply

  module {
    source = "./examples/complete"
  }

  assert {
    condition     = output.bucket_id != null
    error_message = "Bucket OCID must be returned"
  }
  assert {
    condition     = output.namespace != null
    error_message = "Namespace must be resolved"
  }
  assert {
    condition     = output.lifecycle_policy_id != null
    error_message = "Lifecycle policy must be created"
  }
  assert {
    condition     = try(output.bucket_all_attributes.auto_tiering, null) == "InfrequentAccess"
    error_message = "Auto-tiering must be reported as InfrequentAccess"
  }
}
