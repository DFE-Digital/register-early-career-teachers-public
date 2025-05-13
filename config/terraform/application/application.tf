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

  config_variables = merge(
    local.environment_variables,
    local.bigquery_variables,
    {
      ENVIRONMENT_NAME = var.environment
      PGSSLMODE        = local.postgres_ssl_mode
    }
  )
  secret_variables = merge(
    local.bigquery_secrets,
    {
      DATABASE_URL        = module.postgres.url
      BLAZER_DATABASE_URL = var.environment == "production" ? module.infrastructure_secrets.map[local.snapshot_db_kv_secret_name] : module.postgres.url
      REDIS_CACHE_URL     = module.redis-cache.url
    }
  )
}

# Run database migrations
# https://guides.rubyonrails.org/active_record_migrations.html#preparing-the-database
# Terraform waits for this to complete before starting web_application and worker_application
resource "kubernetes_job" "migrations" {
  metadata {
    name      = "${var.service_name}-${var.environment}-migrations"
    namespace = var.namespace
  }

  spec {
    template {
      metadata {
        labels = { app = "${var.service_name}-${var.environment}-migrations" }
        annotations = {
          "logit.io/send"        = "true"
          "fluentbit.io/exclude" = "true"
        }
      }

      spec {
        container {
          name    = "migrate"
          image   = var.docker_image
          command = ["bundle"]
          args    = ["exec", "rails", "db:prepare"]

          env_from {
            config_map_ref {
              name = module.application_configuration.kubernetes_config_map_name
            }
          }

          env_from {
            secret_ref {
              name = module.application_configuration.kubernetes_secret_name
            }
          }

          resources {
            requests = {
              cpu    = module.cluster_data.configuration_map.cpu_min
              memory = "1Gi"
            }
            limits = {
              cpu    = 1
              memory = "1Gi"
            }
          }

          security_context {
            allow_privilege_escalation = false

            seccomp_profile {
              type = "RuntimeDefault"
            }

            capabilities {
              drop = ["ALL"]
              add  = ["NET_BIND_SERVICE"]
            }
          }
        }

        restart_policy = "Never"
      }
    }

    backoff_limit = 1
  }

  wait_for_completion = true

  timeouts {
    create = "11m"
    update = "11m"
  }
}

module "web_application" {
  source     = "./vendor/modules/aks//aks/application"
  depends_on = [kubernetes_job.migrations]

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

  # Uncomment this when we want traffic to be redirected to the maintenance
  # page during disaster recovery (i.e., while waiting for a database to be
  # recreated)
  # send_traffic_to_maintenance_page = true
}

module "worker_application" {
  source     = "./vendor/modules/aks//aks/application"
  depends_on = [kubernetes_job.migrations]

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
