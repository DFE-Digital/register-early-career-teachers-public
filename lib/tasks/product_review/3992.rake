namespace :product_review do
  desc "Set up deferred and withdrawn training periods at Abbey Grove for review (#3992)"
  task "3992" => :environment do
    if Teacher.exists?(trn: "0000060")
      puts "Scenario already set up — Velma Dinkley (TRN 0000060) exists. Aborting."
      next
    end

    abbey_grove = School.find_by!(urn: 1_759_427)
    contract_period = ContractPeriod.find_by!(year: 2023)
    ambition = LeadProvider.find_by!(name: "Ambition Institute")
    active_lead_provider = ActiveLeadProvider.find_by!(lead_provider: ambition, contract_period:)
    school_partnership = SchoolPartnership.find_by!(school: abbey_grove, lead_provider_delivery_partnership: LeadProviderDeliveryPartnership.find_by!(active_lead_provider:))
    schedule = Schedule.find_by!(contract_period_year: 2023, identifier: "ecf-standard-september")

    ApplicationRecord.transaction do
      velma = Teacher.create!(trn: "0000060", trs_first_name: "Velma", trs_last_name: "Dinkley", trs_qts_awarded_on: Date.new(2022, 1, 1), trs_induction_status: "InProgress")
      fred  = Teacher.create!(trn: "0000061", trs_first_name: "Fred",  trs_last_name: "Jones",   trs_qts_awarded_on: Date.new(2022, 1, 1), trs_induction_status: "InProgress")

      velma_at_abbey_grove = ECTAtSchoolPeriod.create!(
        teacher: velma,
        school: abbey_grove,
        started_on: Date.new(2023, 9, 1),
        finished_on: nil
      )

      TrainingPeriod.create!(
        ect_at_school_period: velma_at_abbey_grove,
        school_partnership:,
        schedule:,
        training_programme: "provider_led",
        started_on: Date.new(2023, 9, 1),
        finished_on: Date.new(2024, 3, 1),
        deferred_at: Date.new(2024, 3, 1),
        deferral_reason: "long_term_sickness"
      )

      fred_at_abbey_grove = ECTAtSchoolPeriod.create!(
        teacher: fred,
        school: abbey_grove,
        started_on: Date.new(2023, 9, 1),
        finished_on: nil
      )

      TrainingPeriod.create!(
        ect_at_school_period: fred_at_abbey_grove,
        school_partnership:,
        schedule:,
        training_programme: "provider_led",
        started_on: Date.new(2023, 9, 1),
        finished_on: Date.new(2024, 3, 1),
        withdrawn_at: Date.new(2024, 3, 1),
        withdrawal_reason: "moved_school"
      )
    end

    puts "All done 🎉"
  end
end
