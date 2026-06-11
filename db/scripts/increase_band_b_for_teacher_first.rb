# Increase the max Band B upper limit for Teach First for 2025
# This script will change the max_declarations from 3494 to 4000
#
# $ kubectl exec -it <pod-name> -- bin/rails runner db/scripts/increase_band_b_for_teach_first.rb

name = "Teach First"
contract_period_year = 2025

contract = LeadProvider.find_by!(name:)
  .active_lead_providers.find_by!(contract_period_year:)
  .contracts.sole

band = contract.banded_fee_structure.bands.last

raise "Max declarations #{band.max_declarations} is not 3494!" if band.max_declarations != 3494

band.update!(max_declarations: 4000)

Rails.logger.info "Teach First 2025 contract band B updated: #{band.min_declarations} - #{band.max_declarations}"
