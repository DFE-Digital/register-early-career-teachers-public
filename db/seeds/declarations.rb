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

def assign_uplift(declaration_type, uplift_count)
  return false unless declaration_type == "started"

  uplift = uplift_count < 2 ? true : [true, false].sample
  uplift_count + 1 if uplift
  uplift
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

def describe_statement_declaration(statement)
  print_seed_info("Adding declarations for: #{statement.month} #{statement.year}", indent: 4)
end

def describe_statement(statement)
  lp_name = statement.contract.active_lead_provider.lead_provider.name
  print_seed_info("📜 Statement created for #{lp_name} #{statement.month} #{statement.year} ", indent: 2)
end

def describe_contract(contract)
  lp_name = contract.active_lead_provider.lead_provider.name
  cp_year = contract.active_lead_provider.contract_period.year
  print_seed_info("📜 Contract created for #{lp_name} in #{cp_year}", indent: 4)
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
school = FactoryBot.create(:school)

school_partnership_2024 = FactoryBot.create(:school_partnership,
                                            :with_active_lead_provider,
                                            :for_year,
                                            year: 2024,
                                            school:,
                                            lead_provider: teach_first,
                                            delivery_partner: grain_teaching_school_hub).tap do |partnership|
  describe_school_partnership(partnership)
end

school_partnership_2025 = FactoryBot.create(:school_partnership,
                                            :with_active_lead_provider,
                                            :for_year,
                                            year: 2025,
                                            school:,
                                            lead_provider: teach_first,
                                            delivery_partner: grain_teaching_school_hub).tap do |partnership|
  describe_school_partnership(partnership)
end

teach_first_contract_2024 = FactoryBot.create(:contract,
                                              :for_ecf,
                                              active_lead_provider: school_partnership_2024.active_lead_provider,
                                              banded_fee_structure: ecf_fee_structure).tap do |contract|
  describe_contract(contract)
end

teach_first_contract_2025 = FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider: school_partnership_2025.active_lead_provider, banded_fee_structure: ittecf_fee_structure)

describe_contract(teach_first_contract_2024)
describe_contract(teach_first_contract_2025)

august_statement_2024 = FactoryBot.create(:statement,
                                          :adjustable,
                                          month: 8,
                                          year: 2024,
                                          deadline_date: Date.new(2024, 7, 31),
                                          payment_date: Date.new(2024, 8, 31),
                                          contract: teach_first_contract_2024).tap do |statement|
  describe_statement(statement)
end

october_statement_2024 = FactoryBot.create(:statement,
                                           :adjustable,
                                           month: 10,
                                           year: 2024,
                                           deadline_date: Date.new(2024, 9, 30),
                                           payment_date: Date.new(2024, 10, 31),
                                           contract: teach_first_contract_2024).tap do |statement|
  describe_statement(statement)
end

august_statement_2025 = FactoryBot.create(:statement,
                                          :adjustable,
                                          month: 8,
                                          year: 2025,
                                          deadline_date: Date.new(2025, 7, 31),
                                          payment_date: Date.new(2025, 8, 31),
                                          contract: teach_first_contract_2025).tap do |statement|
  describe_statement(statement)
end

october_statement_2025 = FactoryBot.create(:statement,
                                           :adjustable,
                                           month: 10,
                                           year: 2025,
                                           deadline_date: Date.new(2025, 9, 30),
                                           payment_date: Date.new(2025, 10, 31),
                                           contract: teach_first_contract_2025).tap do |statement|
  describe_statement(statement)
end

uplift_count = 0
results = pre_populate_results

data = { 2024 => { school_partnership: school_partnership_2024, payment_statement: october_statement_2024, clawback_statement: august_statement_2024 },
         2025 => { school_partnership: school_partnership_2025, payment_statement: october_statement_2025, clawback_statement: august_statement_2025 } }

[2024, 2025].each do |year|
  school_partnership = data[year][:school_partnership]
  payment_statement = data[year][:payment_statement]
  clawback_statement  = data[year][:clawback_statement]

  describe_statement_declaration(payment_statement)

  milestones.each do |declaration_type|
    # Create billable declarations
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

    add_to_results(results, year, declaration_type, :ects, n + 1)

    if pupil_premium_uplift
      add_to_results(results, year, declaration_type, :uplifts, n + 1)
    end

    # Create refunded declarations
    n = Random.rand(25)
    FactoryBot.create_list(:declaration, n, :with_ect, :awaiting_clawback,
                           declaration_type:,
                           school_partnership:,
                           payment_statement:,
                           clawback_statement:)

    field = year == 2025 ? :ect_clawbacks : :clawbacks
    add_to_results(results, year, declaration_type, field, n)

    next unless %w[started completed].include?(declaration_type)

    # Create billable declarations for mentors
    FactoryBot.create(:declaration, :with_mentor, :paid,
                      declaration_type:,
                      school_partnership:,
                      payment_statement:)

    add_to_results(results, year, declaration_type, :mentors, 1)

    # Create refunded declarations for mentors
    FactoryBot.create(:declaration, :with_mentor, :awaiting_clawback,
                      declaration_type:,
                      school_partnership:,
                      payment_statement:,
                      clawback_statement:)

    field = year == 2025 ? :mentor_clawbacks : :clawbacks
    add_to_results(results, year, declaration_type, field, 1)
  end

  # Add some manual adjustments to the statement
  FactoryBot.create :statement_adjustment, statement: payment_statement, payment_type: "Big amount", amount: Random.rand(1000)
  FactoryBot.create :statement_adjustment, statement: payment_statement, payment_type: "Negative", amount: Random.rand(100) * -1
end

describe_results(results)
