# Populate contract_id value on fee structures so we can reverse the relationship
#
# $ kubectl exec -it <pod-name> -- bin/rails runner db/scripts/populate_contract_id_on_fee_structures.rb

shared_banded = Contract
  .where.not(banded_fee_structure_id: nil)
  .group(:banded_fee_structure_id)
  .having("COUNT(*) > 1")
  .exists?

shared_flat_rate = Contract
  .where.not(flat_rate_fee_structure_id: nil)
  .group(:flat_rate_fee_structure_id)
  .having("COUNT(*) > 1")
  .exists?

raise "Fee structures are shared between contracts!" if shared_banded || shared_flat_rate

Contract.find_each do |contract|
  contract.banded_fee_structure&.update!(contract_id: contract.id)
  contract.flat_rate_fee_structure&.update!(contract_id: contract.id)
end
