namespace :product_review do
  desc "Set up Abbey Grove ECTs whose provider-led training was withdrawn or deferred, plus an untrained mentor (#4561)"
  task "4561" => :environment do
    abort("Only available for non-production environments") if Rails.env.production?

    if Teacher.exists?(trn: "0000100")
      puts "Scenario already set up — Jessica Hynes (TRN 0000100) exists. Aborting."
      next
    end

    contract_period = ContractPeriod.find_by!(year: 2025)
    abbey_grove = School.find_by!(urn: 1_759_427)
    ambition = LeadProvider.find_by!(name: "Ambition Institute")

    school_partnership = SchoolPartnerships::Search.new(school: abbey_grove, lead_provider: ambition, contract_period:).school_partnerships.first!
    schedule = Schedule.find_by!(contract_period:, identifier: "ecf-standard-september")

    ApplicationRecord.transaction do
      mentor = Teacher.create!(trn: "0000102", trs_first_name: "Ncuti", trs_last_name: "Gatwa", trs_qts_awarded_on: Date.new(2020, 7, 1), trs_induction_status: "Passed")
      mentor_at_school_period = MentorAtSchoolPeriod.create!(teacher: mentor, school: abbey_grove, started_on: Date.new(2025, 9, 1), finished_on: nil)

      withdrawn_ect = Teacher.create!(trn: "0000100", trs_first_name: "Jessica", trs_last_name: "Hynes", trs_qts_awarded_on: Date.new(2025, 7, 1), trs_induction_status: "InProgress")
      withdrawn_ect_at_school_period = ECTAtSchoolPeriod.create!(teacher: withdrawn_ect, school: abbey_grove, started_on: Date.new(2025, 9, 1), finished_on: nil)

      TrainingPeriod.create!(
        ect_at_school_period: withdrawn_ect_at_school_period,
        training_programme: "provider_led",
        school_partnership:,
        schedule:,
        started_on: Date.new(2025, 9, 1),
        finished_on: Date.new(2026, 3, 1),
        withdrawn_at: Date.new(2026, 3, 1),
        withdrawal_reason: "other"
      )

      deferred_ect = Teacher.create!(trn: "0000101", trs_first_name: "Rosamund", trs_last_name: "Pike", trs_qts_awarded_on: Date.new(2025, 7, 1), trs_induction_status: "InProgress")
      deferred_ect_at_school_period = ECTAtSchoolPeriod.create!(teacher: deferred_ect, school: abbey_grove, started_on: Date.new(2025, 9, 1), finished_on: nil)

      TrainingPeriod.create!(
        ect_at_school_period: deferred_ect_at_school_period,
        training_programme: "provider_led",
        school_partnership:,
        schedule:,
        started_on: Date.new(2025, 9, 1),
        finished_on: Date.new(2026, 2, 1),
        deferred_at: Date.new(2026, 2, 1),
        deferral_reason: "parental_leave"
      )

      MentorshipPeriod.create!(mentee: deferred_ect_at_school_period, mentor: mentor_at_school_period, started_on: Date.new(2025, 9, 1), finished_on: nil)
    end

    puts "Jessica Hynes (TRN 0000100) at Abbey Grove School: provider-led training withdrawn, no mentor."
    puts "Rosamund Pike (TRN 0000101) at Abbey Grove School: provider-led training deferred, mentored by Ncuti Gatwa."
    puts "Ncuti Gatwa (TRN 0000102) at Abbey Grove School: mentor eligible for funding with no training periods."
  end
end
