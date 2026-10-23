namespace :product_review do
  desc "Set up a deactivated teacher and an existing replacement record for review (#4329)"
  task :deactivated_teacher_merge, %i[source_trn destination_trn] => :environment do |_task, args|
    abort("Only available for non-production environments") if Rails.env.production?

    source_trn = args[:source_trn].presence || "0000431"
    destination_trn = args[:destination_trn].presence

    if destination_trn.blank?
      unless Rails.application.config.enable_fake_trs_api
        abort("Supply an active destination TRN from TRS preproduction")
      end

      destination_trn = "7000013"
    end

    unless [source_trn, destination_trn].all? { |trn| trn.match?(/\A\d{7}\z/) }
      abort("Both TRNs must contain exactly seven digits")
    end

    abort("Source and destination TRNs must be different") if source_trn == destination_trn

    existing_trns = Teacher.where(trn: [source_trn, destination_trn]).pluck(:trn)

    if existing_trns.any?
      abort("No records created. These TRNs already exist in RECT: #{existing_trns.join(', ')}")
    end

    school = School.find_by!(urn: 1_759_427)
    trs_teacher = TRS::APIClient.build.find_teacher(trn: destination_trn)

    source = nil
    destination = nil

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

      histories = [
        [source, Date.new(2025, 9, 1), Date.new(2025, 10, 31)],
        [source, Date.new(2025, 11, 1), Date.new(2025, 12, 31)],
        [destination, Date.new(2026, 1, 1), nil]
      ]

      histories.each do |teacher, started_on, finished_on|
        school_period = ECTAtSchoolPeriod.create!(
          teacher:,
          school:,
          started_on:,
          finished_on:
        )

        TrainingPeriod.create!(
          ect_at_school_period: school_period,
          training_programme: "school_led",
          started_on:,
          finished_on:
        )
      end
    end

    puts "Created deactivated source: #{source.trn} (teacher #{source.id})"
    puts "Created active destination: #{destination.trn} (teacher #{destination.id})"
    puts "Open /admin/teachers/#{source.id}"
    puts "Choose 'Change the TRN for this deactivated record'."
    puts "Enter replacement TRN: #{destination.trn}"
  end
end
