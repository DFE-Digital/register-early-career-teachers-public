locals {
  snapshot_db_kv_secret_name = "${var.azure_resource_prefix}-${var.service_short}-${var.config_short}-pg-snapshot-database-url"
}

module "application_configuration" {
  source = "./vendor/modules/aks//aks/application_configuration"

  namespace              = var.namespace
  environment            = var.environment
  azure_resource_prefix  = var.azure_resource_prefix
  service_short          = var.service_short
  config_short           = var.config_short
  secret_key_vault_short = "app"

  # Delete for non rails apps
  is_rails_application = true

  config_variables = merge(local.environment_variables,
    {
      ENVIRONMENT_NAME               = var.environment
      PGSSLMODE                      = local.postgres_ssl_mode
      BIGQUERY_PROJECT_ID            = module.dfe_analytics.bigquery_project_id
      BIGQUERY_TABLE_NAME            = module.dfe_analytics.bigquery_table_name
      BIGQUERY_DFE_ANALYTICS_DATASET = module.dfe_analytics.bigquery_dataset

    }
  )
  secret_variables = {
    DATABASE_URL             = module.postgres.url
    BLAZER_DATABASE_URL      = var.environment == "production" ? module.infrastructure_secrets.map[local.snapshot_db_kv_secret_name] : module.postgres.url
    REDIS_CACHE_URL          = module.redis-cache.url
    GOOGLE_CLOUD_CREDENTIALS = module.dfe_analytics.google_cloud_credentials
  }
}

module "web_application" {
  source = "./vendor/modules/aks//aks/application"

  is_web = true

  name         = "web"
  web_port     = 8080
  namespace    = var.namespace
  environment  = var.environment
  service_name = var.service_name

  cluster_configuration_map  = module.cluster_data.configuration_map
  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image = var.docker_image
  command      = var.command

  replicas   = var.webapp_replicas
  max_memory = var.webapp_memory_max

  enable_logit = var.enable_logit
}

module "worker_application" {
  source = "./vendor/modules/aks//aks/application"

  is_web = false

  name         = "worker"
  namespace    = var.namespace
  environment  = var.environment
  service_name = var.service_name

  cluster_configuration_map  = module.cluster_data.configuration_map
  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image = var.docker_image

  command       = ["bundle", "exec", "rake", "solid_queue:start"]
  probe_command = ["pgrep", "-f", "solid-queue-worker"]

  replicas   = var.worker_replicas
  max_memory = var.worker_memory_max

  enable_logit   = var.enable_logit
  enable_gcp_wif = true
}
