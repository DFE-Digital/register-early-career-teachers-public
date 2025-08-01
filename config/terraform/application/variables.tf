variable "command" {
  type    = list(string)
  default = []
}
variable "cluster" {
  description = "AKS cluster where this app is deployed. Either 'test' or 'production'"
}
variable "namespace" {
  description = "AKS namespace where this app is deployed"
}
variable "environment" {
  description = "Name of the deployed environment in AKS"
}
variable "azure_resource_prefix" {
  description = "Standard resource prefix. Usually s189t01 (test) or s189p01 (production)"
}

variable "azure_maintenance_window" {
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = null
}

variable "config" {
  description = "Name of the environment configuration, e.g. review, staging, production..."
}
variable "config_short" {
  description = "Short name of the environment configuration, e.g. dv, st, pd..."
}
variable "service_name" {
  description = "Full name of the service. Lowercase and hyphen separated"
}
variable "service_short" {
  description = "Short name to identify the service. Up to 6 charcters."
}
variable "deploy_azure_backing_services" {
  default     = true
  description = "Deploy real Azure backing services like databases, as opposed to containers inside of AKS"
}
variable "deploy_snapshot_database" {
  type    = string
  default = false
}
variable "enable_postgres_ssl" {
  default     = true
  description = "Enforce SSL connection from the client side"
}
variable "azure_enable_backup_storage" {
  default     = false
  description = "Create a storage account to store database dumps"
}
variable "docker_image" {
  description = "Docker image full name to identify it in the registry. Includes docker registry, repository and tag e.g.: ghcr.io/dfe-digital/teacher-pay-calculator:673f6309fd0c907014f44d6732496ecd92a2bcd0"
}
variable "external_url" {
  default     = null
  description = "Healthcheck URL for StatusCake monitoring"
}
variable "statuscake_contact_groups" {
  default     = [291418]
  description = "ID of the contact group in statuscake web UI"
}
variable "enable_monitoring" {
  default     = false
  description = "Enable monitoring and alerting"
}

variable "webapp_memory_max" {
  type    = string
  default = "1Gi"
}

variable "webapp_replicas" {
  type    = number
  default = 1
}

variable "worker_memory_max" {
  type    = string
  default = "1Gi"
}

variable "worker_replicas" {
  type    = number
  default = 1
}

variable "postgres_flexible_server_sku" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "postgres_snapshot_flexible_server_sku" {
  default = "B_Standard_B1ms"
}

variable "postgres_enable_high_availability" {
  type    = bool
  default = false
}

variable "enable_logit" { default = false }

variable "gcp_table_deletion_protection" {
  type    = bool
  default = null
}
variable "create_bigquery_dataset" {
  default     = true
  description = "Create bigquery dataset and events table"
}

variable "run_as_non_root" {
  type        = bool
  default     = true
  description = "Whether to enforce that containers must run as non-root user"
}

locals {
  postgres_ssl_mode = var.enable_postgres_ssl ? "require" : "disable"

  environment_variables = yamldecode(file("${path.module}/config/${var.config}.yml"))

  bigquery_variables = var.create_bigquery_dataset ? {
    BIGQUERY_PROJECT_ID            = module.dfe_analytics[0].bigquery_project_id
    BIGQUERY_TABLE_NAME            = module.dfe_analytics[0].bigquery_table_name
    BIGQUERY_DFE_ANALYTICS_DATASET = module.dfe_analytics[0].bigquery_dataset
  } : {}
  bigquery_secrets = var.create_bigquery_dataset ? {
    GOOGLE_CLOUD_CREDENTIALS = module.dfe_analytics[0].google_cloud_credentials
  } : {}
}

variable "commands" {
  description = "list of required docker image commands for k8s job to run"
  type        = list(string)
  default     = ["bundle"]
}

variable "arguments" {
  description = "list of required docker image arguments for k8s job to run"
  type        = list(string)
  default     = ["exec", "rails", "db:prepare"]
}

variable "job_name" {
  description = "name of the k8s job to run"
  type        = string
  default     = "migrations"
}
