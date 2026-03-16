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

def assign_uplift(declaration_type, uplift_count)
  return false unless declaration_type == "started"

  uplift = uplift_count < 2 ? true : [true, false].sample
  uplift_count + 1 if uplift
  uplift
end

def pre_populate_results
  results = {}
  headers.each_key do |year|
    results[year] = {}
    milestones.each do |milestone|
      results[year][milestone] = { type: milestone.ljust(12), ects: 0, mentors: 0, uplifts: 0, clawbacks: 0, mentor_clawbacks: 0, ect_clawbacks: 0 }
    end
  end
  results
end

def add_to_results(results, year, declaration_type, field, amount)
  results[year][declaration_type][field] += amount
end

def describe_results(results)
  print_seed_info("Statements:")

  headers.each_key do |year|
    columns = headers[year]

    print_seed_info("Year: #{year}", indent: 2, colour: :green)
    print_seed_info(columns.map { it.humanize.titleize.ljust(20) }.join, indent: 4, colour: :blue)
    milestones.each do |milestone|
      result = results[year][milestone]

      print_seed_info(
        columns.map { result[it.to_sym].to_s.ljust(20) }.join,
        indent: 4
      )
    end
  end
end

def headers
  {
    2024 => %w[type ects mentors uplifts clawbacks],
    2025 => %w[type ects mentors mentor_clawbacks ect_clawbacks]
  }
end

def describe_declaration(declaration, period_type)
  return unless declaration

  print_seed_info("* #{declaration.declaration_type} - #{declaration.payment_status} for #{period_type}", indent: 8)
end

def describe_statement_declaration(statement)
  print_seed_info("📜 Declarations for: #{statement.month} #{statement.year}", indent: 4)
end

def describe_statement(statement)
  lp_name = statement.contract.active_lead_provider.lead_provider.name
  print_seed_info("📜 Statement #{statement.id} for #{lp_name} #{statement.month} #{statement.year}", indent: 2)
end

def describe_contract(contract)
  lp_name = contract.active_lead_provider.lead_provider.name
  cp_year = contract.active_lead_provider.contract_period.year
  print_seed_info("Contract for #{lp_name} in #{cp_year}", indent: 4)
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

ECF_BOUNDARIES = [
  { min: 1, max: 5 },
  { min: 6, max: 10 },
  { min: 11, max: 20 },
  { min: 21, max: 40 },
].freeze

ITTECF_BOUNDARIES = [
  { min: 1, max: 5 },
  { min: 6, max: 10 },
  { min: 11, max: 15 },
  { min: 16, max: 20 },
].freeze

print_seed_info("Creating Statements")

ecf_fee_structure = FactoryBot.create(:contract_banded_fee_structure, :with_bands, declaration_boundaries: ECF_BOUNDARIES)
ittecf_fee_structure = FactoryBot.create(:contract_banded_fee_structure, :with_bands, declaration_boundaries: ITTECF_BOUNDARIES)

teach_first = LeadProvider.find_by!(name: "Teach First")
grain_teaching_school_hub = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")
abbey_grove_school = School.find_by!(urn: 1_759_427)
cp_2024 = ContractPeriod.find_by!(year: 2024)
cp_2025 = ContractPeriod.find_by!(year: 2025)

teach_first_grain_2024 = ActiveLeadProvider.find_by!(contract_period: cp_2024, lead_provider: teach_first)
teach_first_grain_2025 = ActiveLeadProvider.find_by!(contract_period: cp_2025, lead_provider: teach_first)
teach_first_contract_2024 = FactoryBot.create(:contract, :for_ecf, active_lead_provider: teach_first_grain_2024, banded_fee_structure: ecf_fee_structure)
teach_first_contract_2025 = FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider: teach_first_grain_2025, banded_fee_structure: ittecf_fee_structure)

describe_contract(teach_first_contract_2024)
describe_contract(teach_first_contract_2025)

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

october_statement_2024 = FactoryBot.create(:statement, :paid_in_month, month: 10, year: 2024, contract: teach_first_contract_2024).tap do |statement|
  describe_statement(statement)
end
november_statement_2024 = FactoryBot.create(:statement, :paid_in_month, month: 11, year: 2024, contract: teach_first_contract_2024).tap do |statement|
  describe_statement(statement)
end
october_statement_2025 = FactoryBot.create(:statement, :paid_in_month, month: 10, year: 2025, contract: teach_first_contract_2025).tap do |statement|
  describe_statement(statement)
end
november_statement_2025 = FactoryBot.create(:statement, :paid_in_month, month: 11, year: 2025, contract: teach_first_contract_2025).tap do |statement|
  describe_statement(statement)
end

school_partnerships = [teach_first_grain_abbey_grove_2024, teach_first_grain_abbey_grove_2025]
payment_statements = [november_statement_2024, november_statement_2025]
statement_pairs = [[october_statement_2024, november_statement_2024], [october_statement_2025, november_statement_2025]]
all_statements = statement_pairs.flatten

uplift_count = 0
results = pre_populate_results

payment_statements.each do |payment_statement|
  describe_statement_declaration(payment_statement)
  school_partnerships.each do |school_partnership|
    alp = payment_statement.contract.active_lead_provider
    school_alp = school_partnership.lead_provider_delivery_partnership.active_lead_provider
    next unless alp == school_alp

    describe_school_partnership(school_partnership)

    milestones.each do |declaration_type|
      n = Random.rand(25)
      pupil_premium_uplift = assign_uplift(declaration_type, uplift_count)
      FactoryBot.create_list(:declaration, n, :with_ect, :paid,
                             declaration_type:,
                             school_partnership:,
                             pupil_premium_uplift:,
                             payment_statement:)

      FactoryBot.create(:declaration, :with_ect, :voided,
                        declaration_type:,
                        school_partnership:,
                        payment_statement:)

      year = payment_statement.contract.contract_period.year

      add_to_results(results, year, declaration_type, :ects, n + 1)
      if pupil_premium_uplift
        add_to_results(results, year, declaration_type, :uplifts, n + 1)
      end

      next unless %w[started completed].include?(declaration_type)

      FactoryBot.create(:declaration, :with_mentor, :paid,
                        declaration_type:,
                        school_partnership:,
                        payment_statement:)

      add_to_results(results, year, declaration_type, :mentors, 1)
    end
  end
end

statement_pairs.each do |payment_statement, clawback_statement|
  school_partnerships.each do |school_partnership|
    alp = payment_statement.contract.active_lead_provider
    school_alp = school_partnership.lead_provider_delivery_partnership.active_lead_provider
    next unless alp == school_alp

    describe_school_partnership(school_partnership)

    milestones.each do |declaration_type|
      n = Random.rand(25)
      FactoryBot.create_list(:declaration, n, :with_ect, :awaiting_clawback,
                             declaration_type:,
                             school_partnership:,
                             payment_statement:,
                             clawback_statement:)

      year = clawback_statement.contract.contract_period.year
      field = year == 2025 ? :ect_clawbacks : :clawbacks
      add_to_results(results, year, declaration_type, field, n)

      next unless %w[started completed].include?(declaration_type)

      FactoryBot.create(:declaration, :with_mentor, :awaiting_clawback,
                        declaration_type:,
                        school_partnership:,
                        payment_statement:,
                        clawback_statement:)

      field = year == 2025 ? :mentor_clawbacks : :clawbacks
      add_to_results(results, year, declaration_type, field, 1)
    end
  end
end

describe_results(results)

all_statements.each do |statement|
  FactoryBot.create :statement_adjustment, statement:, payment_type: "Big amount", amount: Random.rand(1000)
  FactoryBot.create :statement_adjustment, statement:, payment_type: "Negative", amount: Random.rand(100) * -1
end
