call_off_contract_pre_2025 = FactoryBot.create(:call_off_contract, :banded)
call_off_contract_post_2024_banded = FactoryBot.create(:call_off_contract, :banded)
call_off_contract_post_2024_flat_rate = FactoryBot.create(:call_off_contract, :flat_rate)

Statement.includes(:payment_declarations, :clawback_declarations).find_each do |statement|
  print_seed_info("Statement ##{statement.id} - #{statement.active_lead_provider.lead_provider.name} - #{statement.month}/#{statement.year}", indent: 2)

  if statement.contract_period.year < 2025
    call_off_contract_assignment = FactoryBot.create(:call_off_contract_assignment, call_off_contract: call_off_contract_pre_2025, statement:)

    statement.declarations.each do |declaration|
      next unless declaration.payment_status.in?(%w[eligible payable paid])

      declaration.update!(call_off_contract_assignment:)
    end
  else
    banded_call_off_contract_assignment = FactoryBot.create(:call_off_contract_assignment, call_off_contract: call_off_contract_post_2024_banded, statement:)
    flat_rate_call_off_contract_assignment = FactoryBot.create(:call_off_contract_assignment, call_off_contract: call_off_contract_post_2024_flat_rate, statement:)

    statement.declarations.each do |declaration|
      next unless declaration.payment_status.in?(%w[eligible payable paid])

      if declaration.training_period.for_ect?
        declaration.update!(call_off_contract_assignment: banded_call_off_contract_assignment)
      else
        declaration.update!(call_off_contract_assignment: flat_rate_call_off_contract_assignment)
      end
    end
  end
end
