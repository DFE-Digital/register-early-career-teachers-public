# Increase the max Band B upper limit for EDT for 2025
# This script will change the max_declarations from 3102 to 4000
#
# $ kubectl exec -it <pod-name> -- bin/rails runner db/scripts/increase_band_b_for_edt.rb

begin
  name = "Education Development Trust"
  contract_period_year = 2025

  lead_provider = LeadProvider.find_by!(name:)
  active_lead_provider = ActiveLeadProvider.find_by!(lead_provider:, contract_period_year:)

  contract = Contract.find_by!(active_lead_provider:)

  band = contract.banded_fee_structure.bands.order(min_declarations: :desc).second

  raise "Max declarations #{band.max_declarations} is not 3102!" if band.max_declarations != 3102

  band.update!(max_declarations: 4000)

  puts "Band B updated: #{band.min_declarations} - #{band.max_declarations}"
end
