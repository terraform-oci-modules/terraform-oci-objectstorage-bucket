################################################################################
# Mock unit tests: fast, free, no real OCI resources.
#
# Exercises input->config mapping logic (namespace auto-resolution, tag merge
# order, retention rule mapping) against the module root with a mocked OCI
# provider (command = plan). Run on its own:
#   terraform test -filter=tests/unit_mappings.tftest.hcl
################################################################################

mock_provider "oci" {
  mock_data "oci_objectstorage_namespace" {
    defaults = {
      namespace = "mockedtenancyns"
    }
  }
}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  bucket         = "test-bucket"
}

# --- Namespace auto-resolution -------------------------------------------------

run "namespace_auto_resolves_when_not_set" {
  command = plan

  assert {
    condition     = oci_objectstorage_bucket.this[0].namespace == "mockedtenancyns"
    error_message = "namespace = null (default) must auto-resolve from data.oci_objectstorage_namespace"
  }
}

run "namespace_uses_explicit_value_when_set" {
  command = plan

  variables {
    namespace = "myexplicitns"
  }

  assert {
    condition     = oci_objectstorage_bucket.this[0].namespace == "myexplicitns"
    error_message = "an explicit namespace must be used verbatim, bypassing the data source lookup"
  }
}

# --- Tag merge order -------------------------------------------------------

run "bucket_tags_override_global_tags" {
  command = plan

  variables {
    tags        = { team = "global", env = "shared" }
    bucket_tags = { team = "bucket-specific" }
  }

  assert {
    condition     = oci_objectstorage_bucket.this[0].freeform_tags["team"] == "bucket-specific"
    error_message = "bucket_tags must override a same-key entry from the global tags map"
  }

  assert {
    condition     = oci_objectstorage_bucket.this[0].freeform_tags["env"] == "shared"
    error_message = "a global tags entry not overridden by bucket_tags must still be present"
  }

  assert {
    condition     = oci_objectstorage_bucket.this[0].freeform_tags["Name"] == "test-bucket"
    error_message = "freeform_tags must always include a Name key set to var.bucket"
  }
}

# --- Retention rule mapping --------------------------------------------------

run "retention_rule_duration_mapping" {
  command = plan

  variables {
    retention_rules = [
      {
        display_name = "compliance-hold"
        time_amount  = 30
        time_unit    = "DAYS"
      }
    ]
  }

  assert {
    condition     = one(oci_objectstorage_bucket.this[0].retention_rules).duration[0].time_amount == "30"
    error_message = "retention_rules[].time_amount must map into the nested duration block"
  }

  assert {
    condition     = one(oci_objectstorage_bucket.this[0].retention_rules).duration[0].time_unit == "DAYS"
    error_message = "retention_rules[].time_unit must map into the nested duration block"
  }
}

# --- Plan-time guards (resource preconditions) ---------------------------------
#
# These fail the plan rather than warn, so expect_failures names the resource
# that carries the precondition.

run "auto_tiering_lifecycle_conflict_is_flagged" {
  command = plan

  variables {
    auto_tiering = "InfrequentAccess"
    lifecycle_rule = [
      {
        name        = "bad-rule"
        action      = "INFREQUENT_ACCESS"
        time_amount = 30
      }
    ]
  }

  expect_failures = [oci_objectstorage_bucket.this]
}

run "retention_rules_versioning_conflict_is_flagged" {
  command = plan

  variables {
    versioning = "Enabled"
    retention_rules = [
      {
        display_name = "compliance-hold"
        time_amount  = 30
        time_unit    = "DAYS"
      }
    ]
  }

  expect_failures = [oci_objectstorage_bucket.this]
}

run "replication_plans_without_source_versioning" {
  command = plan

  # Unlike S3, OCI does not require versioning on the replication source.
  variables {
    replication_policy = {
      name                    = "to-phx"
      destination_region_name = "us-phoenix-1"
      destination_bucket_name = "dest"
    }
  }

  assert {
    condition     = oci_objectstorage_replication_policy.this[0].destination_bucket_name == "dest"
    error_message = "An unversioned source bucket must accept a replication policy"
  }
}

run "replication_with_versioning_plans" {
  command = plan

  variables {
    versioning = "Enabled"
    replication_policy = {
      name                    = "to-phx"
      destination_region_name = "us-phoenix-1"
      destination_bucket_name = "dest"
    }
  }

  assert {
    condition     = oci_objectstorage_replication_policy.this[0].destination_region_name == "us-phoenix-1"
    error_message = "A versioned bucket must accept a replication policy"
  }
}
