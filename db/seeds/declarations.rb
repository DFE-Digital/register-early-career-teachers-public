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

def describe_declaration(declaration, period_type)
  print_seed_info("* #{declaration.declaration_type} - #{declaration.payment_status} for #{period_type}", indent: 8)
end

def describe_statement_declaration(statement)
  print_seed_info("📜 Declarations for: #{statement.month} #{statement.year}", indent: 4)
end

def describe_statement(statement)
  lp_name = statement.contract.active_lead_provider.lead_provider.name
  print_seed_info("📜 Statement #{statement.id} for #{lp_name} #{statement.month} #{statement.year}", indent: 2)
end

def describe_school_partnership(school_partnership)
  school_partnership.lead_provider_delivery_partnership.delivery_partner.name
  lead_provider_name = school_partnership.lead_provider_delivery_partnership.active_lead_provider.lead_provider.name
  school_partnership.lead_provider_delivery_partnership.active_lead_provider.contract_period.year
  school_name = school_partnership.school.gias_school.name

  print_seed_info("Partnership #{school_name} #{lead_provider_name}", indent: 6)
end

def milestones
  %w[started retained-1 retained-2 retained-3 retained-4 extended-1 extended-2 extended-3 completed]
end

teach_first = LeadProvider.find_by!(name: "Teach First")
grain_teaching_school_hub = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")
abbey_grove_school = School.find_by!(urn: 1_759_427)
cp_2024 = ContractPeriod.find_by!(year: 2024)
cp_2025 = ContractPeriod.find_by!(year: 2025)

teach_first_grain_2024 = ActiveLeadProvider.find_by!(contract_period: cp_2024, lead_provider: teach_first)
teach_first_grain_2025 = ActiveLeadProvider.find_by!(contract_period: cp_2025, lead_provider: teach_first)
teach_first_contract_2024 = Contract.where(active_lead_provider: teach_first_grain_2024, contract_type: :ecf).first
teach_first_contract_2025 = Contract.where(active_lead_provider: teach_first_grain_2025, contract_type: :ittecf_ectp).first

teach_first_grain_abbey_grove_2024 = find_or_create_school_partnership!(
  school: abbey_grove_school,
  lead_provider: teach_first,
  delivery_partner: grain_teaching_school_hub,
  contract_period: cp_2024
)

teach_first_grain_abbey_grove_2025 = find_or_create_school_partnership!(
  school: abbey_grove_school,
  lead_provider: teach_first,
  delivery_partner: grain_teaching_school_hub,
  contract_period: cp_2025
)

august_statement_2024 = FactoryBot.create(:statement, :paid_in_month, month: 8, year: 2024, contract: teach_first_contract_2024).tap do |statement|
  describe_statement(statement)
end
september_statement_2024 = FactoryBot.create(:statement, :paid_in_month, month: 9, year: 2024, contract: teach_first_contract_2024).tap do |statement|
  describe_statement(statement)
end
august_statement_2025 = FactoryBot.create(:statement, :paid_in_month, month: 8, year: 2025, contract: teach_first_contract_2025).tap do |statement|
  describe_statement(statement)
end
september_statement_2025 = FactoryBot.create(:statement, :paid_in_month, month: 9, year: 2025, contract: teach_first_contract_2025).tap do |statement|
  describe_statement(statement)
end

school_partnerships = [teach_first_grain_abbey_grove_2024, teach_first_grain_abbey_grove_2025]
statements = [september_statement_2024, september_statement_2025]

statements.each do |payment_statement|
  describe_statement_declaration(payment_statement)
  school_partnerships.each do |school_partnership|
    alp = payment_statement.contract.active_lead_provider
    school_alp = school_partnership.lead_provider_delivery_partnership.active_lead_provider
    next unless alp == school_alp

    describe_school_partnership(school_partnership)

    milestones.each do |declaration_type|
      FactoryBot.create(:declaration, :with_ect, :paid,
                        declaration_type:,
                        school_partnership:,
                        payment_statement:).tap do |declaration|
        describe_declaration(declaration, "ECT")
      end

      FactoryBot.create(:declaration, :with_ect, :voided,
                        declaration_type:,
                        school_partnership:,
                        payment_statement:).tap do |declaration|
        describe_declaration(declaration, "ECT")
      end

      if declaration_type == "started" || declaration_type == "completed"
        FactoryBot.create(:declaration, :with_mentor, :paid,
                          declaration_type:,
                          school_partnership:,
                          payment_statement:).tap do |declaration|
          describe_declaration(declaration, "Mentor")
        end
      end
    end
  end
end

statement_pairs = [[august_statement_2024, september_statement_2024], [august_statement_2025, september_statement_2025]]

# statement_pairs.each do |payment_statement, clawback_statement|
#   describe_statement_declaration(clawback_statement)
#   school_partnerships.each do |school_partnership|
#     alp = payment_statement.contract.active_lead_provider
#     school_alp = school_partnership.lead_provider_delivery_partnership.active_lead_provider
#     next unless alp == school_alp

#     describe_school_partnership(school_partnership)

#     milestones.each do |declaration_type|
#       FactoryBot.create(:declaration, :with_ect, :awaiting_clawback,
#                         declaration_type:,
#                         school_partnership:,
#                         payment_statement:,
#                         clawback_statement:).tap do |declaration|
#         describe_declaration(declaration, "ECT")
#       end
#       FactoryBot.create(:declaration, :with_mentor, :awaiting_clawback,
#                         declaration_type:,
#                         school_partnership:,
#                         payment_statement:,
#                         clawback_statement:).tap do |declaration|
#         describe_declaration(declaration, "Mentor")
#       end
#     end
#   end
# end
