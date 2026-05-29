run "creates_public_access_buckets" {
  command = apply

  module {
    source = "./examples/public-access"
  }

  assert {
    condition     = output.public_read_bucket_id != null
    error_message = "ObjectRead bucket must be created"
  }
  assert {
    condition     = output.public_read_no_list_bucket_id != null
    error_message = "ObjectReadWithoutList bucket must be created"
  }
}
