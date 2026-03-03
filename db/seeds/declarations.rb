def find_or_create_school_partnership!(school:, delivery_partner:, lead_provider:, contract_period:)
  active_lead_provider = ActiveLeadProvider.find_by!(
    lead_provider:,
    contract_period_year: contract_period.year
  )

  lead_provider_delivery_partnership = LeadProviderDeliveryPartnership.find_or_create_by!(
    active_lead_provider:,
    delivery_partner:
  )

  SchoolPartnership.find_or_create_by!(
    school:,
    lead_provider_delivery_partnership:
  )
end

def milestones
  %w[started retained-1 retained-2 retained-3 retained-4 completed]
end

teach_first = LeadProvider.find_by!(name: "Teach First")
grain_teaching_school_hub = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")
abbey_grove_school = School.find_by!(urn: 1_759_427)
cp_2024 = ContractPeriod.find_by!(year: 2024)

teach_first_grain_2024 = ActiveLeadProvider.find_by!(contract_period: cp_2024, lead_provider: teach_first)
teach_first_contract_2024 = Contract.where(active_lead_provider: teach_first_grain_2024, contract_type: :ecf).first

teach_first_grain_abbey_grove_2024 = find_or_create_school_partnership!(
  school: abbey_grove_school,
  lead_provider: teach_first,
  delivery_partner: grain_teaching_school_hub,
  contract_period: cp_2024
)

august_statement = FactoryBot.create(:statement, :paid_in_month, paid_in_month: 8, contract: teach_first_contract_2024)
september_statement = FactoryBot.create(:statement, :paid_in_month, paid_in_month: 9, contract: teach_first_contract_2024)

# THIS DOESN'T WORK because the milestones are set
milestones.each do |declaration_type|
  print_seed_info("Creating declarations for #{declaration_type}")

  FactoryBot.create(:declaration, :with_ect,    :paid, declaration_type:, school_partnership: teach_first_grain_abbey_grove_2024, payment_statement: august_statement)
  FactoryBot.create(:declaration, :with_mentor, :paid, declaration_type:, school_partnership: teach_first_grain_abbey_grove_2024, payment_statement: august_statement)
end




