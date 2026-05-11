namespace :product_review do
  desc "Set up replacement-schedule-across-schools scenario at Abbey Grove (#3870)"
  task "3870" => :environment do
    if Teacher.exists?(trn: "0000050")
      puts "Scenario already set up — Rik Mayall (TRN 0000050) exists. Aborting."
      next
    end

    abbey_grove = School.find_by!(urn: 1_759_427)
    brookfield  = School.find_by!(urn: 2_976_163)

    cp_2023 = ContractPeriod.find_by!(year: 2023)
    cp_2024 = ContractPeriod.find_by!(year: 2024)

    ambition       = LeadProvider.find_by!(name: "Ambition Institute")
    artisan        = DeliveryPartner.find_by!(name: "Artisan Education Group")
    golden_leaf    = AppropriateBodyPeriod.find_by!(name: "Golden Leaf Teaching School Hub")
    south_yorks    = AppropriateBodyPeriod.find_by!(name: "South Yorkshire Studio Hub")

    brookfield_partnership  = find_or_create_partnership!(school: brookfield,  lead_provider: ambition, delivery_partner: artisan, contract_period: cp_2023)
    abbey_grove_partnership = find_or_create_partnership!(school: abbey_grove, lead_provider: ambition, delivery_partner: artisan, contract_period: cp_2024)

    sched_2023 = Schedule.find_by!(contract_period_year: 2023, identifier: "ecf-standard-september")
    sched_2024 = Schedule.find_by!(contract_period_year: 2024, identifier: "ecf-standard-september")

    ApplicationRecord.transaction do
      rik    = Teacher.create!(trn: "0000050", trs_first_name: "Rik",    trs_last_name: "Mayall",    trs_qts_awarded_on: Date.new(2021, 1, 1), trs_induction_status: "InProgress")
      adrian = Teacher.create!(trn: "0000051", trs_first_name: "Adrian", trs_last_name: "Edmondson", trs_qts_awarded_on: Date.new(2021, 1, 1), trs_induction_status: "InProgress")
      nigel  = Teacher.create!(trn: "0000052", trs_first_name: "Nigel",  trs_last_name: "Planer",    trs_qts_awarded_on: Date.new(2021, 1, 1), trs_induction_status: "InProgress")

      # Brookfield (previous school): Adrian mentored Rik with declared training

      adrian_at_brookfield = MentorAtSchoolPeriod.create!(
        teacher: adrian,
        school: brookfield,
        started_on: Date.new(2023, 9, 1),
        finished_on: Date.new(2024, 8, 31)
      )

      adrian_brookfield_training = TrainingPeriod.create!(
        mentor_at_school_period: adrian_at_brookfield,
        school_partnership: brookfield_partnership,
        schedule: sched_2023,
        training_programme: "provider_led",
        started_on: Date.new(2023, 9, 1),
        finished_on: Date.new(2024, 8, 31)
      )

      rik_at_brookfield = ECTAtSchoolPeriod.create!(
        teacher: rik,
        school: brookfield,
        started_on: Date.new(2023, 9, 1),
        finished_on: Date.new(2024, 8, 31),
        school_reported_appropriate_body: south_yorks
      )

      TrainingPeriod.create!(
        ect_at_school_period: rik_at_brookfield,
        school_partnership: brookfield_partnership,
        schedule: sched_2023,
        training_programme: "provider_led",
        started_on: Date.new(2023, 9, 1),
        finished_on: Date.new(2024, 8, 31)
      )

      MentorshipPeriod.create!(
        mentor: adrian_at_brookfield,
        mentee: rik_at_brookfield,
        started_on: Date.new(2023, 9, 1),
        finished_on: Date.new(2024, 8, 31)
      )

      # The signal that "training started": a non-voided declaration whose date
      # falls inside the previous mentorship.
      Declaration.create!(
        training_period: adrian_brookfield_training,
        declaration_type: "started",
        declaration_date: Date.new(2023, 12, 15),
        evidence_type: "training-event-attended",
        payment_status: :no_payment,
        clawback_status: :no_clawback,
        api_id: SecureRandom.uuid,
        delivery_partner_when_created: artisan
      )

      # Abbey Grove (current school): Rik moved here, no current mentor

      rik_at_abbey_grove = ECTAtSchoolPeriod.create!(
        teacher: rik,
        school: abbey_grove,
        started_on: Date.new(2024, 9, 1),
        finished_on: nil,
        school_reported_appropriate_body: golden_leaf
      )

      TrainingPeriod.create!(
        ect_at_school_period: rik_at_abbey_grove,
        school_partnership: abbey_grove_partnership,
        schedule: sched_2024,
        training_programme: "provider_led",
        started_on: Date.new(2024, 9, 1),
        finished_on: nil
      )

      # Nigel is registered as a mentor at Abbey Grove with no training period yet
      MentorAtSchoolPeriod.create!(
        teacher: nigel,
        school: abbey_grove,
        started_on: Date.new(2025, 9, 1),
        finished_on: nil
      )
    end

    puts
    puts "=" * 78
    puts "  Replacement schedule across schools (#3870)"
    puts "=" * 78
    puts
    puts "  State seeded by this task:"
    puts "    - Rik Mayall: ECT at Abbey Grove (no current mentor)"
    puts "    - Adrian Edmondson: prior closed mentorship of Rik at Brookfield, with"
    puts "      a non-voided 'started' declaration during that mentorship"
    puts "    - Nigel Planer: registered as a mentor at Abbey Grove, no training period"
    puts "      and not yet linked to Rik"
    puts
    puts "  To verify:"
    puts "    1. Sign in as Bob Belcher (Abbey Grove School)"
    puts "    2. Open Rik's record and assign Nigel as his mentor"
    puts "    3. Expect Nigel's new training period to be given a `replacement`"
    puts "       schedule (would be `standard` without this PR)"
    puts
  end
end

def find_or_create_partnership!(school:, lead_provider:, delivery_partner:, contract_period:)
  active_lead_provider = ActiveLeadProvider.find_or_create_by!(lead_provider:, contract_period_year: contract_period.year)
  lpdp = LeadProviderDeliveryPartnership.find_or_create_by!(active_lead_provider:, delivery_partner:)
  SchoolPartnership.find_or_create_by!(school:, lead_provider_delivery_partnership: lpdp)
end
