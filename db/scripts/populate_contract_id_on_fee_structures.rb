# Populate contract_id value on fee structures so we can reverse the relationship
#
# $ kubectl exec -it <pod-name> -- bin/rails runner db/scripts/populate_contract_id_on_fee_structures.rb

Contract.find_each do |contract|
  contract.banded_fee_structure&.update!(contract_id: contract.id)
  contract.flat_rate_fee_structure&.update!(contract_id: contract.id)
end
