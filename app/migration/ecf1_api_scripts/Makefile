# extract data from ECF1 API into JSON files
# You'll need to have a local ECF1 app running connected to a snapshot DB
# and you'll need to have the provider keys or recreated new ones for this
# purpose:
#
# CpdLeadProvider.joins(:lead_provider).to_h do |cpd_lead_provider|
#   token = LeadProviderApiToken.create_with_random_token!(
#     cpd_lead_provider: cpd_lead_provider
#   )
#
#   [cpd_lead_provider.name, token]
# end
#
# store the relevant token under each provider target at the bottom
# of this file

OUTPUT_DIR := ./api_data
FETCH_SCRIPT := ./fetch_api_data.zsh
HOST := "http://localhost:3000"
PARTICIPANTS_ENDPOINT := "${HOST}/api/v3/participants/ecf"
DECLARATIONS_ENDPOINT := "${HOST}/api/v3/participant-declarations"
TRANSFERS_ENDPOINT := "${HOST}/api/v3/participants/ecf/transfers"
UNFUNDED_MENTORS_ENDPOINT := "${HOST}/api/v3/unfunded-mentors/ecf"

.phony: all
all: clean_all
	@$(MAKE) ambition_all
	@$(MAKE) bpn_all
	@$(MAKE) capita_all
	@$(MAKE) edt_all
	@$(MAKE) tf_all
	@$(MAKE) ucl_all
	@$(MAKE) niot_all

.phony: all_endpoints
all_endpoints: participants declarations transfers unfunded_mentors

.phony: ambition_all
ambition_all: ambition all_endpoints
.phony: bpn_all
bpn_all: bpn all_endpoints
.phony: capita_all
capita_all: capita all_endpoints
.phony: edt_all
edt_all: edt all_endpoints
.phony: tf_all
tf_all: tf all_endpoints
.phony: ucl_all
ucl_all: ucl all_endpoints
.phony: niot_all
niot_all: niot all_endpoints

.phony: participants
participants:
	@echo "🧑‍🎓 Participants"
	@${FETCH_SCRIPT} -u ${PARTICIPANTS_ENDPOINT} -k ${PROVIDER_KEY} -o "${DIRPATH}/participants"

.phony: declarations
declarations:
	@echo "🛃 Declarations"
	@${FETCH_SCRIPT} -u ${DECLARATIONS_ENDPOINT} -k ${PROVIDER_KEY} -o "${DIRPATH}/declarations"

.phony: transfers
transfers:
	@echo "📦 Transfers"
	@${FETCH_SCRIPT} -u ${TRANSFERS_ENDPOINT} -k ${PROVIDER_KEY} -o "${DIRPATH}/transfers"

.phony: unfunded_mentors
unfunded_mentors:
	@echo "💸 Unfunded mentors"
	@${FETCH_SCRIPT} -u ${UNFUNDED_MENTORS_ENDPOINT} -k ${PROVIDER_KEY} -o "${DIRPATH}/unfunded_mentors"

.phony: clean
clean:
	@echo "🧹 cleaning"
	@rm -rf ${DIRPATH}

.phony: clean_all
clean_all:
	@echo "🧹 cleaning all"
	@rm -rf ${OUTPUT_DIR}

.phony: ambition
ambition:
	$(eval PROVIDER_NAME="ambition")
	$(eval PROVIDER_KEY="senBkNxgPLXrmQqZQeiG")
	$(eval DIRPATH="${OUTPUT_DIR}/ambition")

.phony: bpn
bpn:
	$(eval PROVIDER_NAME="bpn")
	$(eval PROVIDER_KEY="hENauXegzNYG52ptc98e")
	$(eval DIRPATH="${OUTPUT_DIR}/bpn")

.phony: capita
capita:
	$(eval PROVIDER_NAME="capita")
	$(eval PROVIDER_KEY="4FTVDrHmx1i3Ur9mxTg2")
	$(eval DIRPATH="${OUTPUT_DIR}/capita")

.phony: edt
edt:
	$(eval PROVIDER_NAME="edt")
	$(eval PROVIDER_KEY="f1yGRfArhVwog2hy1wNJ")
	$(eval DIRPATH="${OUTPUT_DIR}/edt")

.phony: tf
tf:
	$(eval PROVIDER_NAME="tf")
	$(eval PROVIDER_KEY="Wnsjee-MDouLjD4wG2tz")
	$(eval DIRPATH="${OUTPUT_DIR}/tf")

.phony: ucl
ucl:
	$(eval PROVIDER_NAME="ucl")
	$(eval PROVIDER_KEY="H_dAP3X_Xy-F3iPd3e3y")
	$(eval DIRPATH="${OUTPUT_DIR}/ucl")

.phony: niot
niot:
	$(eval PROVIDER_NAME="niot")
	$(eval PROVIDER_KEY="Dqfmx8PQP4D5Fqky3exn")
	$(eval DIRPATH="${OUTPUT_DIR}/niot")

