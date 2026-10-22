namespace :product_review do
  desc "Set up a Brookfield school-led ECT whose mentor is in provider-led training at Abbey Grove (#4595)"
  task "4595" => :environment do
    abort("Only available for non-production environments") if Rails.env.production?

    if Teacher.exists?(trn: "0004595")
      puts "Scenario already set up — Nadia Okafor (TRN 0004595) exists. Aborting."
      next
    end

    contract_period_2026 = ContractPeriod.find_by!(year: 2026)
    abbey_grove = School.find_by!(urn: 1_759_427)
    brookfield = School.find_by!(urn: 2_976_163)
    teach_first = LeadProvider.find_by!(name: "Teach First")

    framework_agreement_2026 = FrameworkAgreement.find_by!(lead_provider: teach_first, contract_period: contract_period_2026)
    schedule_2026 = Schedule.find_by!(contract_period: contract_period_2026, identifier: "ecf-standard-september")

    ApplicationRecord.transaction do
      mentor = Teacher.create!(trn: "0004596", trs_first_name: "Tom", trs_last_name: "Brennan", trs_qts_awarded_on: Date.new(2020, 7, 1))

      abbey_grove_mentor_period = MentorAtSchoolPeriod.create!(teacher: mentor, school: abbey_grove, started_on: Date.new(2026, 9, 1), finished_on: nil)
      TrainingPeriod.create!(
        mentor_at_school_period: abbey_grove_mentor_period,
        training_programme: "provider_led",
        started_on: Date.new(2026, 9, 1),
        finished_on: nil,
        expression_of_interest: framework_agreement_2026,
        schedule: schedule_2026
      )

      brookfield_mentor_period = MentorAtSchoolPeriod.create!(teacher: mentor, school: brookfield, started_on: Date.new(2026, 9, 1), finished_on: nil)

      ect = Teacher.create!(trn: "0004595", trs_first_name: "Nadia", trs_last_name: "Okafor", trs_qts_awarded_on: Date.new(2026, 7, 1), trs_induction_status: "InProgress")
      ect_at_school_period = ECTAtSchoolPeriod.create!(teacher: ect, school: brookfield, started_on: Date.new(2026, 9, 1), finished_on: nil)
      TrainingPeriod.create!(ect_at_school_period:, training_programme: "school_led", started_on: Date.new(2026, 9, 1), finished_on: nil)

      MentorshipPeriod.create!(mentee: ect_at_school_period, mentor: brookfield_mentor_period, started_on: Date.new(2026, 9, 1), finished_on: nil)
    end

    puts "Nadia Okafor (TRN 0004595) at Brookfield: school-led, mentored by Tom Brennan, who is in provider-led training with Teach First at Abbey Grove."
  end
end
