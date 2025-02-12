provider "google" {
  project = "ecf-bq"
}

module "dfe_analytics" {
  source = "./vendor/modules/aks//aks/dfe_analytics"

  azure_resource_prefix = var.azure_resource_prefix
  cluster               = var.cluster
  namespace             = var.namespace
  service_short         = "ecf2"
  environment           = var.environment
  gcp_keyring           = "ecf-key-ring"
  gcp_key               = "ecf-key"
  gcp_taxonomy_id       = 6302091323314055162
  gcp_policy_tag_id     = 301313311867345339

  gcp_table_deletion_protection = var.gcp_table_deletion_protection
}
