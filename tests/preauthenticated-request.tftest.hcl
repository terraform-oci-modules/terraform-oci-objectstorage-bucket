run "creates_preauthenticated_requests" {
  command = apply

  module {
    source = "./examples/preauthenticated-request"
  }

  assert {
    condition     = output.bucket_id != null
    error_message = "Bucket must be created"
  }
  # access_uri is computed at apply time - that's why this test uses command = apply.
  assert {
    condition     = length(nonsensitive(output.preauthenticated_request_uris)) == 2
    error_message = "Both PARs (bucket-listing-read, upload-handoff) must be created"
  }
  assert {
    condition     = alltrue([for uri in nonsensitive(values(output.preauthenticated_request_uris)) : length(uri) > 0])
    error_message = "Each PAR must expose a non-empty access URI"
  }
}
