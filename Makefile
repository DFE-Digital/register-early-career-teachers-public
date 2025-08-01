ARM_TEMPLATE_TAG=1.1.13
RG_TAGS={"Product" : "Early Careers Framework"}
REGION=UK South
SERVICE_NAME=cpd-ec2
SERVICE_SHORT=cpdec2
DOCKER_REPOSITORY=ghcr.io/dfe-digital/register-early-career-teachers-public

# Handle BSD and GNU sed differences
SED_INPLACE ?= $(shell if sed --version >/dev/null 2>&1; then echo "-i"; else echo "-i ''"; fi)

serve-documentation-site:
	cd documentation/site && bundle exec nanoc live --handler webrick --port 8000

build-documentation-site:
	cd documentation/site && bundle exec nanoc

help:
	@grep -E '^[a-zA-Z\._\-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

docker-compose-build:
	docker-compose build --build-arg BUNDLE_FLAGS='--jobs=4 --no-binstubs --no-cache' --parallel

.PHONY: review
review: test-cluster ## Specify review AKS environment
	$(if ${PULL_REQUEST_NUMBER},,$(error Missing PULL_REQUEST_NUMBER))
	$(eval ENVIRONMENT=review-${PULL_REQUEST_NUMBER})
	$(eval export TF_VAR_environment=${ENVIRONMENT})
	$(eval include config/global_config/review.sh)

.PHONY: staging
staging: test-cluster
	$(eval include config/global_config/staging.sh)

migration: production-cluster
	$(eval include config/global_config/migration.sh)

sandbox: production-cluster
	$(eval include config/global_config/sandbox.sh)

production: production-cluster
	$(if $(or ${SKIP_CONFIRM}, ${CONFIRM_PRODUCTION}), , $(error Missing CONFIRM_PRODUCTION=yes))
	$(eval include config/global_config/production.sh)

domains:
	$(eval include config/global_config/domains.sh)

composed-variables:
	$(eval RESOURCE_GROUP_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-rg)
	$(eval KEYVAULT_NAMES='("${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-app-kv", "${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-inf-kv")')
	$(eval STORAGE_ACCOUNT_NAME=${AZURE_RESOURCE_PREFIX}${SERVICE_SHORT}${CONFIG_SHORT}tfsa)
	$(eval LOG_ANALYTICS_WORKSPACE_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-log)

ci:
	$(eval AUTO_APPROVE=-auto-approve)
	$(eval SKIP_AZURE_LOGIN=true)
	$(eval SKIP_CONFIRM=true)

set-azure-account:
	[ "${SKIP_AZURE_LOGIN}" != "true" ] && az account set -s ${AZURE_SUBSCRIPTION} || true

vendor-modules:
	rm -rf config/terraform/application/vendor/modules/aks
	git -c advice.detachedHead=false clone --depth=1 --single-branch --branch ${TERRAFORM_MODULES_TAG} https://github.com/DFE-Digital/terraform-modules.git config/terraform/application/vendor/modules/aks

terraform-init: vendor-modules composed-variables set-azure-account
	$(if ${DOCKER_IMAGE_TAG}, , $(eval DOCKER_IMAGE_TAG=main))

	terraform -chdir=config/terraform/application init -upgrade -reconfigure \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=${ENVIRONMENT}_kubernetes.tfstate

	$(eval export TF_VAR_azure_resource_prefix=${AZURE_RESOURCE_PREFIX})
	$(eval export TF_VAR_config=${CONFIG})
	$(eval export TF_VAR_config_short=${CONFIG_SHORT})
	$(eval export TF_VAR_service_name=${SERVICE_NAME})
	$(eval export TF_VAR_service_short=${SERVICE_SHORT})
	$(eval export TF_VAR_docker_image=${DOCKER_REPOSITORY}:${DOCKER_IMAGE_TAG})

terraform-plan: terraform-init
	terraform -chdir=config/terraform/application plan -var-file "config/${CONFIG}.tfvars.json"

terraform-apply: terraform-init
	terraform -chdir=config/terraform/application apply -var-file "config/${CONFIG}.tfvars.json" ${AUTO_APPROVE}

## DOCKER_IMAGE_TAG=fake-image make review terraform-unlock PULL_REQUEST_NUMBER=4169 LOCK_ID=123456
## DOCKER_IMAGE_TAG=fake-image make staging terraform-unlock LOCK_ID=123456
.PHONY: terraform-unlock
terraform-unlock: terraform-init
	terraform -chdir=config/terraform/application force-unlock ${LOCK_ID}

.PHONY: terraform-destroy
terraform-destroy: terraform-init
	terraform -chdir=config/terraform/application destroy -var-file "config/${CONFIG}.tfvars.json" ${AUTO_APPROVE}

set-what-if:
	$(eval WHAT_IF=--what-if)

arm-deployment: composed-variables set-azure-account
	$(if ${DISABLE_KEYVAULTS},, $(eval KV_ARG=keyVaultNames=${KEYVAULT_NAMES}))
	$(if ${ENABLE_KV_DIAGNOSTICS}, $(eval KV_DIAG_ARG=enableDiagnostics=${ENABLE_KV_DIAGNOSTICS} logAnalyticsWorkspaceName=${LOG_ANALYTICS_WORKSPACE_NAME}),)

	az deployment sub create --name "resourcedeploy-tsc-$(shell date +%Y%m%d%H%M%S)" \
		-l "${REGION}" --template-uri "https://raw.githubusercontent.com/DFE-Digital/tra-shared-services/${ARM_TEMPLATE_TAG}/azure/resourcedeploy.json" \
		--parameters "resourceGroupName=${RESOURCE_GROUP_NAME}" 'tags=${RG_TAGS}' \
		"tfStorageAccountName=${STORAGE_ACCOUNT_NAME}" "tfStorageContainerName=terraform-state" \
		${KV_ARG} \
		${KV_DIAG_ARG} \
		"enableKVPurgeProtection=${KV_PURGE_PROTECTION}" \
		${WHAT_IF}

deploy-arm-resources: arm-deployment ## Validate ARM resource deployment. Usage: make domains validate-arm-resources

validate-arm-resources: set-what-if arm-deployment ## Validate ARM resource deployment. Usage: make domains validate-arm-resources

test-cluster:
	$(eval CLUSTER_RESOURCE_GROUP_NAME=s189t01-tsc-ts-rg)
	$(eval CLUSTER_NAME=s189t01-tsc-test-aks)

production-cluster:
	$(eval CLUSTER_RESOURCE_GROUP_NAME=s189p01-tsc-pd-rg)
	$(eval CLUSTER_NAME=s189p01-tsc-production-aks)

get-cluster-credentials: set-azure-account
	az aks get-credentials --overwrite-existing -g ${CLUSTER_RESOURCE_GROUP_NAME} -n ${CLUSTER_NAME}
	kubelogin convert-kubeconfig -l $(if ${AAD_LOGIN_METHOD},${AAD_LOGIN_METHOD},azurecli)

.PHONY: install-konduit
install-konduit: ## Install the konduit script, for accessing backend services
	[ ! -f bin/konduit.sh ] \
		&& curl -s https://raw.githubusercontent.com/DFE-Digital/teacher-services-cloud/master/scripts/konduit.sh -o bin/konduit.sh \
		&& chmod +x bin/konduit.sh \
		|| true

konduit-cleanup:
	sed $(SED_INPLACE) -e '/url\: "postgres/d' config/database.yml; \
	exit 0

define KONDUIT_CONNECT
	trap 'make konduit-cleanup' INT; \
	tmp_file=$$(mktemp); \
	$(MAKE) konduit-cleanup; \
	{ \
		(tail -f -n0 "$$tmp_file" & ) | grep -q "postgres://"; \
		postgres_url=$$(grep -o 'postgres://[^ ]*' "$$tmp_file"); \
		echo "$$postgres_url"; \
		sed $(SED_INPLACE) -e "s|ecf2_development|&\\n  url: \"$$postgres_url\"|g" config/database.yml; \
	} & \
	bin/konduit.sh -d
endef

# Creates a konduit to the DB and points development to it. The konduit URL is removed when the konduit is closed.
konduit: get-cluster-credentials set-namespace
	$(KONDUIT_CONNECT) ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-pg -n ${NAMESPACE} -k ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-app-kv cpd-ec2-${CONFIG}-web -- psql > "$$tmp_file"
	exit 0

# Creates a konduit to the snapshot DB and points development to it. The konduit URL is removed when the konduit is closed.
konduit-snapshot: get-cluster-credentials set-namespace
	$(KONDUIT_CONNECT) ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-pg-snapshot -n ${NAMESPACE} -k ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-app-kv cpd-ec2-${CONFIG}-web -- psql > "$$tmp_file"
	exit 0

set-namespace:
	$(eval NAMESPACE=$(shell jq -r '.namespace' "config/terraform/application/config/${CONFIG}.tfvars.json"))

aks-console: get-cluster-credentials set-namespace
	kubectl -n ${NAMESPACE} exec -ti --tty deployment/${SERVICE_NAME}-${ENVIRONMENT}-web -- /bin/sh -c "cd /app && bundle exec rails c"

aks-ssh: get-cluster-credentials set-namespace
	kubectl -n ${NAMESPACE} exec -ti --tty deployment/${SERVICE_NAME}-${ENVIRONMENT}-web -- /bin/sh

action-group-resources: set-azure-account # make env_aks action-group-resources ACTION_GROUP_EMAIL=notificationemail@domain.com . Must be run before setting enable_monitoring=true for each subscription
	$(if $(ACTION_GROUP_EMAIL), , $(error Please specify a notification email for the action group))
	echo ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-mn-rg
	az group create -l uksouth -g ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-mn-rg --tags "Product=Early Careers Framework" "Environment=Test" "Service Offering=Teacher services cloud"
	az monitor action-group create -n ${AZURE_RESOURCE_PREFIX}-ecf2 -g ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-mn-rg --short-name ${AZURE_RESOURCE_PREFIX}-ecf2 --action email ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-email ${ACTION_GROUP_EMAIL}

domains-infra-init: domains composed-variables set-azure-account
	rm -rf config/terraform/domains/infrastructure/vendor/modules/domains
	git -c advice.detachedHead=false clone --depth=1 --single-branch --branch ${TERRAFORM_MODULES_TAG} https://github.com/DFE-Digital/terraform-modules.git config/terraform/domains/infrastructure/vendor/modules/domains

	terraform -chdir=config/terraform/domains/infrastructure init -reconfigure -upgrade \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=domains_infrastructure.tfstate

domains-infra-plan: domains domains-infra-init  ## Terraform plan for DNS infrastructure (DNS zone and front door). Usage: make domains-infra-plan
	terraform -chdir=config/terraform/domains/infrastructure plan -var-file config/zones.tfvars.json

domains-infra-apply: domains domains-infra-init  ## Terraform apply for DNS infrastructure (DNS zone and front door). Usage: make domains-infra-apply
	terraform -chdir=config/terraform/domains/infrastructure apply -var-file config/zones.tfvars.json ${AUTO_APPROVE}

domains-init: domains composed-variables set-azure-account
	rm -rf config/terraform/domains/environment_domains/vendor/modules/domains
	git -c advice.detachedHead=false clone --depth=1 --single-branch --branch ${TERRAFORM_MODULES_TAG} https://github.com/DFE-Digital/terraform-modules.git config/terraform/domains/environment_domains/vendor/modules/domains

	terraform -chdir=config/terraform/domains/environment_domains init -upgrade -reconfigure \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=${ENVIRONMENT}.tfstate

domains-plan: domains-init  ## Terraform plan for DNS environment domains. Usage: make development domains-plan
	terraform -chdir=config/terraform/domains/environment_domains plan -var-file config/${CONFIG}.tfvars.json

domains-apply: domains-init ## Terraform apply for DNS environment domains. Usage: make development domains-apply
	terraform -chdir=config/terraform/domains/environment_domains apply -var-file config/${CONFIG}.tfvars.json ${AUTO_APPROVE}


maintenance-image-push:
	$(if ${GITHUB_TOKEN},, $(error Provide a valid Github token with write:packages permissions as GITHUB_TOKEN variable))
	$(if ${MAINTENANCE_IMAGE_TAG},, $(eval export MAINTENANCE_IMAGE_TAG=$(shell date +%s)))
	docker build --platform linux/amd64 -t ghcr.io/dfe-digital/register-early-career-teachers-public-maintenance:${MAINTENANCE_IMAGE_TAG} maintenance_page
	echo ${GITHUB_TOKEN} | docker login ghcr.io -u USERNAME --password-stdin
	docker push ghcr.io/dfe-digital/register-early-career-teachers-public-maintenance:${MAINTENANCE_IMAGE_TAG}

maintenance-fail-over: get-cluster-credentials
	$(eval export CONFIG)
	./maintenance_page/scripts/failover.sh

enable-maintenance: maintenance-image-push maintenance-fail-over

disable-maintenance: get-cluster-credentials
	$(eval export CONFIG)
	./maintenance_page/scripts/failback.sh
