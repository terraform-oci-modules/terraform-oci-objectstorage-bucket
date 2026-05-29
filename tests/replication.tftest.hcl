run "creates_cross_region_replication" {
  command = apply

  module {
    source = "./examples/replication"
  }

  assert {
    condition     = output.source_bucket_id != null
    error_message = "Source bucket must be created"
  }
  assert {
    condition     = output.destination_bucket_id != null
    error_message = "Destination bucket must be created in the destination region"
  }
  assert {
    condition     = output.replication_policy_id != null
    error_message = "Replication policy must be created"
  }
  # status flips to ACTIVE shortly after creation; CLIENT_ERROR signals a misconfig
  # (e.g. same-region destination or destination versioning off).
  assert {
    condition     = output.replication_status != "CLIENT_ERROR"
    error_message = "Replication policy reported a CLIENT_ERROR — check region and versioning"
  }
}
