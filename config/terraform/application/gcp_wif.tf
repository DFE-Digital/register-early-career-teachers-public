provider "google" {
  project = local.gcp_project
}

module "dfe_analytics" {
  source = "./vendor/modules/aks//aks/dfe_analytics"
  count  = var.create_bigquery_dataset ? 1 : 0

  azure_resource_prefix = var.azure_resource_prefix
  cluster               = var.cluster
  namespace             = var.namespace
  service_short         = "ecf2"
  environment           = var.environment
  gcp_keyring           = local.gcp_keyring
  gcp_key               = local.gcp_key
  gcp_taxonomy_id       = local.gcp_taxonomy_id
  gcp_policy_tag_id     = local.gcp_policy_tag_id

  gcp_table_deletion_protection = var.gcp_table_deletion_protection
}
