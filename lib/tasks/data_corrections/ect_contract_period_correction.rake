namespace :data_corrections do
  desc "Correct an ECT training period assigned to the wrong contract period"

  # Replacement IDs are optional overrides when automatic lookup is ambiguous
  task :ect_contract_period_correction,
       %i[
         training_period_id
         teacher_id
         current_contract_period_year
         replacement_contract_period_year
         replacement_schedule_id
         replacement_school_partnership_id
         replacement_expression_of_interest_id
         allow_finished_training_period
       ] => :environment do |_task, args|
    training_period =
      TrainingPeriod.find(args.fetch(:training_period_id))

    replacement_schedule =
      if args[:replacement_schedule_id].present?
        Schedule.find(args[:replacement_schedule_id])
      end

    replacement_school_partnership =
      if args[:replacement_school_partnership_id].present?
        SchoolPartnership.find(
          args[:replacement_school_partnership_id]
        )
      end

    replacement_expression_of_interest =
      if args[:replacement_expression_of_interest_id].present?
        FrameworkAgreement.find(
          args[:replacement_expression_of_interest_id]
        )
      end

    allow_finished_training_period =
      args[:allow_finished_training_period] == "true"

    correction =
      DataCorrections::ECTContractPeriodCorrection.new(
        training_period:,
        teacher_id: args.fetch(:teacher_id).to_i,
        current_contract_period_year:
          args.fetch(:current_contract_period_year).to_i,
        replacement_contract_period_year:
          args.fetch(:replacement_contract_period_year).to_i,
        replacement_schedule:,
        replacement_school_partnership:,
        replacement_expression_of_interest:,
        allow_finished_training_period:
      )

    replacement = correction.preview

    print_training_period = ->(period) do
      contract_period =
        period.school_partnership&.contract_period ||
        period.expression_of_interest_contract_period ||
        period.schedule&.contract_period

      puts "  Teacher: #{period.ect_at_school_period.teacher_id}"
      puts "  Training period: #{period.id}"
      puts "  Contract period: #{contract_period&.year}"
      puts "  Schedule: #{period.schedule_id}"
      puts "  School partnership: #{period.school_partnership_id}"
      puts "  Expression of interest: #{period.expression_of_interest_id}"
    end

    puts
    puts "Before:"
    print_training_period.call(training_period)

    puts
    puts "Proposed replacement:"
    puts "  Contract period: #{replacement.fetch(:contract_period).year}"
    puts "  Schedule: #{replacement.fetch(:schedule).id}"
    puts(
      "  School partnership: " \
      "#{replacement[:school_partnership]&.id}"
    )
    puts(
      "  Expression of interest: " \
      "#{replacement[:expression_of_interest]&.id}"
    )
    puts(
      "  Finished period correction allowed: " \
      "#{allow_finished_training_period}"
    )

    teacher_id = training_period.ect_at_school_period.teacher_id

    puts
    puts "Enter teacher ID #{teacher_id} to continue:"

    abort "Correction cancelled" unless
      $stdin.gets&.chomp == teacher_id.to_s

    corrected_training_period = correction.call

    puts
    puts "After:"
    print_training_period.call(corrected_training_period)
  end
end
