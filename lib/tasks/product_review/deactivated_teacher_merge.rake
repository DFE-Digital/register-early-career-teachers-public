namespace :product_review do
  desc "Set up teacher records with training, mentorships and declarations for merging (#4329)"
  task :deactivated_teacher_merge, %i[source_trn destination_trn mentor_trn] => :environment do |_task, args|
    abort("Only available for non-production environments") if Rails.env.production?

    source_trn = args[:source_trn].presence || "0000431"
    destination_trn = args[:destination_trn].presence
    mentor_trn = args[:mentor_trn].presence || "0000433"

    if destination_trn.blank?
      unless Rails.application.config.enable_fake_trs_api
        abort("Supply an active destination TRN from TRS preproduction")
      end

      destination_trn = "7000013"
    end

    trns = [source_trn, destination_trn, mentor_trn]

    unless trns.all? { |trn| trn.match?(/\A\d{7}\z/) }
      abort("All TRNs must contain exactly seven digits")
    end

    abort("All three TRNs must be different") unless trns.uniq.size == 3

    existing_trns = Teacher.where(trn: trns).pluck(:trn)

    if existing_trns.any?
      abort("No records created. These TRNs already exist in RECT: #{existing_trns.join(', ')}")
    end

    school = School.find_by!(urn: 1_759_427)
    contract_period = ContractPeriod.find_by!(year: 2025)
    lead_provider = LeadProvider.find_by!(name: "Teach First")

    school_partnership = SchoolPartnerships::Search.new(
      school:,
      lead_provider:,
      contract_period:
    ).school_partnerships.first!

    schedule = Schedule.find_by!(
      contract_period:,
      identifier: "ecf-standard-september"
    )

    trs_teacher = TRS::APIClient.build.find_teacher(trn: destination_trn)

    source = nil
    destination = nil
    mentor = nil

    ApplicationRecord.transaction do
      source = Teacher.create!(
        trn: source_trn,
        trs_first_name: trs_teacher.trs_first_name,
        trs_last_name: trs_teacher.trs_last_name,
        trs_response: "gone",
        trs_qts_awarded_on: Date.new(2023, 1, 1),
        trs_induction_status: "InProgress"
      )

      destination = Teacher.create!(
        trn: destination_trn,
        trs_first_name: trs_teacher.trs_first_name,
        trs_last_name: trs_teacher.trs_last_name,
        trs_response: "ok",
        trs_qts_awarded_on: Date.new(2023, 1, 1),
        trs_induction_status: "InProgress"
      )

      mentor = Teacher.create!(
        trn: mentor_trn,
        trs_first_name: "Ruth",
        trs_last_name: "Jones",
        trs_qts_awarded_on: Date.new(2020, 7, 1),
        trs_induction_status: "Passed"
      )

      mentor_school_period = MentorAtSchoolPeriod.create!(
        teacher: mentor,
        school:,
        started_on: Date.new(2025, 9, 1),
        finished_on: nil
      )

      histories = [
        [source, Date.new(2025, 9, 1), Date.new(2025, 10, 31), "started"],
        [source, Date.new(2025, 11, 1), Date.new(2025, 12, 31), "retained-1"],
        [destination, Date.new(2026, 1, 1), nil, "retained-2"]
      ]

      histories.each do |teacher, started_on, finished_on, declaration_type|
        school_period = ECTAtSchoolPeriod.create!(
          teacher:,
          school:,
          working_pattern: "full_time",
          started_on:,
          finished_on:
        )

        training_period = TrainingPeriod.create!(
          ect_at_school_period: school_period,
          training_programme: "provider_led",
          school_partnership:,
          schedule:,
          started_on:,
          finished_on:
        )

        MentorshipPeriod.create!(
          mentee: school_period,
          mentor: mentor_school_period,
          started_on:,
          finished_on:
        )

        Declaration.create!(
          training_period:,
          declaration_type:,
          evidenced_at: started_on + 14.days,
          evidence_type: "training-event-attended",
          payment_status: :no_payment,
          clawback_status: :no_clawback,
          api_id: SecureRandom.uuid,
          delivery_partner_when_created: training_period.delivery_partner
        )
      end
    end

    puts "Created deactivated source: #{source.trn} (teacher #{source.id})"
    puts "Created active destination: #{destination.trn} (teacher #{destination.id})"
    puts "Created mentor: #{mentor.trn} (teacher #{mentor.id})"
    puts "Created three school periods, training periods, mentorships and declarations."
    puts "Open /admin/teachers/#{source.id}"
    puts "Choose 'Change the TRN for this deactivated record'."
    puts "Enter replacement TRN: #{destination.trn}"
  end
end
