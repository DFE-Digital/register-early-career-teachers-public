provider "google" {
  project = "ecf-bq"
}

module "dfe_analytics" {
  source = "./vendor/modules/aks//aks/dfe_analytics"

  azure_resource_prefix = var.azure_resource_prefix
  cluster               = var.cluster
  namespace             = var.namespace
  service_short         = var.service_short
  environment           = var.environment
  gcp_dataset           = "ecf_events_${var.config}"
}
