call_off_contract_banded = FactoryBot.create(:call_off_contract_banded)
call_off_contract_flat_rate = FactoryBot.create(:call_off_contract_flat_rate)

Statement.find_each do |statement|
  print_seed_info("Statement ##{statement.id} - #{statement.active_lead_provider.lead_provider.name} - #{statement.month}/#{statement.year}", indent: 2)

  if statement.contract_period.year < 2025
    FactoryBot.create(:call_off_contract_assignment, statement:, declaration_resolver_type: :all, call_off_contract_banded:, call_off_contract_flat_rate: nil)
  else
    FactoryBot.create(:call_off_contract_assignment, statement:, declaration_resolver_type: :ect, call_off_contract_banded:)
    FactoryBot.create(:call_off_contract_assignment, statement:, declaration_resolver_type: :mentor, call_off_contract_flat_rate:)
  end
end
