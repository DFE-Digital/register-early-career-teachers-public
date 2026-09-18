namespace :product_review do
  desc "Set up an Abbey Grove ECT who trained provider-led in 2025, moved to school-led, and has an untrained mentor (#4435)"
  task "4435" => :environment do
    abort("Only available for non-production environments") if Rails.env.production?

    if Teacher.exists?(trn: "0000090")
      puts "Scenario already set up — Leila Haddad (TRN 0000090) exists. Aborting."
      next
    end

    contract_period_2025 = ContractPeriod.find_by!(year: 2025)
    contract_period_2026 = ContractPeriod.find_by!(year: 2026)
    abbey_grove = School.find_by!(urn: 1_759_427)
    teach_first = LeadProvider.find_by!(name: "Teach First")

    school_partnership_2025 = SchoolPartnerships::Search.new(school: abbey_grove, lead_provider: teach_first, contract_period: contract_period_2025).school_partnerships.first!
    schedule_2025 = Schedule.find_by!(contract_period: contract_period_2025, identifier: "ecf-standard-september")

    ApplicationRecord.transaction do
      ect = Teacher.create!(trn: "0000090", trs_first_name: "Leila", trs_last_name: "Haddad", trs_qts_awarded_on: Date.new(2025, 7, 1), trs_induction_status: "InProgress")
      ect_at_school_period = ECTAtSchoolPeriod.create!(teacher: ect, school: abbey_grove, started_on: Date.new(2025, 9, 1), finished_on: nil)

      TrainingPeriod.create!(
        ect_at_school_period:,
        training_programme: "provider_led",
        started_on: Date.new(2025, 9, 1),
        finished_on: contract_period_2025.finished_on,
        school_partnership: school_partnership_2025,
        schedule: schedule_2025
      )

      TrainingPeriod.create!(
        ect_at_school_period:,
        training_programme: "school_led",
        started_on: contract_period_2026.started_on,
        finished_on: nil
      )

      mentor = Teacher.create!(trn: "0000091", trs_first_name: "Sam", trs_last_name: "Whitfield", trs_qts_awarded_on: Date.new(2025, 7, 1), trs_induction_status: "InProgress")
      mentor_at_school_period = MentorAtSchoolPeriod.create!(teacher: mentor, school: abbey_grove, started_on: Date.new(2025, 9, 1), finished_on: nil)

      MentorshipPeriod.create!(mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on: contract_period_2026.started_on, finished_on: nil)
    end

    puts "Leila Haddad (TRN 0000090) at Abbey Grove School: school-led, previously with Teach First in 2025, mentored by Sam Whitfield."
  end
end
