namespace :product_review do
  desc "Set up Abbey Grove ECTs without mentors, and untrained mentors, for the assign existing mentor journeys (#4478)"
  task "4478" => :environment do
    abort("Only available for non-production environments") if Rails.env.production?

    if Teacher.exists?(trn: "0000100")
      puts "Scenario already set up — Daniel Kaluuya (TRN 0000100) exists. Aborting."
      next
    end

    abbey_grove = School.find_by!(urn: 1_759_427)
    current_contract_period = ContractPeriod.find_by!(year: 2026)
    lapsed_contract_period = ContractPeriod.find_by!(year: 2023)

    ambition = LeadProvider.find_by!(name: "Ambition Institute")
    capita = LeadProvider.find_by!(name: "Capita")

    create_teacher = ->(trn, first_name, last_name) do
      Teacher.create!(trn:, trs_first_name: first_name, trs_last_name: last_name, trs_qts_awarded_on: Date.new(2025, 7, 1), trs_induction_status: "InProgress")
    end

    create_provider_led_ect = ->(trn, first_name, last_name, lead_provider:, contract_period:) do
      ect_at_school_period = ECTAtSchoolPeriod.create!(teacher: create_teacher.call(trn, first_name, last_name), school: abbey_grove, started_on: contract_period.started_on, finished_on: nil)

      TrainingPeriod.create!(
        ect_at_school_period:,
        training_programme: "provider_led",
        started_on: contract_period.started_on,
        finished_on: nil,
        expression_of_interest: FrameworkAgreement.find_by!(lead_provider:, contract_period:),
        schedule: Schedule.find_by!(contract_period:, identifier: "ecf-standard-september")
      )
    end

    create_untrained_mentor = ->(trn, first_name, last_name) do
      MentorAtSchoolPeriod.create!(teacher: create_teacher.call(trn, first_name, last_name), school: abbey_grove, started_on: current_contract_period.started_on, finished_on: nil)
    end

    ApplicationRecord.transaction do
      create_provider_led_ect.call("0000100", "Daniel", "Kaluuya", lead_provider: ambition, contract_period: current_contract_period)
      create_provider_led_ect.call("0000101", "Florence", "Pugh", lead_provider: ambition, contract_period: current_contract_period)
      create_provider_led_ect.call("0000102", "Paapa", "Essiedu", lead_provider: capita, contract_period: lapsed_contract_period)

      create_untrained_mentor.call("0000103", "Olivia", "Williams")
      create_untrained_mentor.call("0000104", "Adrian", "Lester")
      create_untrained_mentor.call("0000105", "Lesley", "Manville")
    end

    puts
    puts "=" * 78
    puts "  Assign existing mentor journeys (#4478)"
    puts "=" * 78
    puts
    puts "  Created at Abbey Grove School with no mentor or mentor training:"
    puts "    - Daniel Kaluuya and Florence Pugh, ECTs training with #{ambition.name} (#{current_contract_period.year})"
    puts "    - Paapa Essiedu, an ECT training with #{capita.name} through a #{lapsed_contract_period.year} expression"
    puts "      of interest. #{capita.name} has no framework agreement for #{current_contract_period.year}."
    puts "    - Olivia Williams, Adrian Lester and Lesley Manville, mentors"
    puts
    puts "  Signed in as the Abbey Grove school user, choose 'Assign a mentor for this ECT' on:"
    puts "    Journey A (ECT's lead provider trains the mentor): Daniel Kaluuya, with Olivia Williams"
    puts "    Journey B (choose a different lead provider):       Florence Pugh, with Adrian Lester"
    puts "    Journey C (no available lead provider):            Paapa Essiedu, with Lesley Manville"
    puts
  end
end
