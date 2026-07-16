namespace :support do
  desc <<~DESC.squish
    Move withdrawal details from an erroneous training period to the original
    training period and correct the linked end dates.

    Usage:
      rake "support:correct_ect_withdrawal_history[
        ECT_AT_SCHOOL_PERIOD_ID,
        ORIGINAL_TRAINING_PERIOD_ID,
        ERRONEOUS_WITHDRAWN_TRAINING_PERIOD_ID,
        CORRECTED_END_DATE
      ]"
  DESC
  task :correct_ect_withdrawal_history,
       %i[
         ect_at_school_period_id
         original_training_period_id
         erroneous_withdrawn_training_period_id
         corrected_end_date
       ] => :environment do |_task, args|
    required_arguments = %i[
      ect_at_school_period_id
      original_training_period_id
      erroneous_withdrawn_training_period_id
      corrected_end_date
    ]

    missing_arguments = required_arguments.select do |argument|
      args[argument].blank?
    end

    if missing_arguments.any?
      raise ArgumentError,
            "Missing required arguments: #{missing_arguments.join(', ')}"
    end

    ect_at_school_period = ECTAtSchoolPeriod.find(
      args[:ect_at_school_period_id]
    )

    original_training_period = TrainingPeriod.find(
      args[:original_training_period_id]
    )

    erroneous_withdrawn_training_period = TrainingPeriod.find(
      args[:erroneous_withdrawn_training_period_id]
    )

    corrected_end_date = Date.iso8601(
      args[:corrected_end_date]
    )

    teacher = ect_at_school_period.teacher

    puts "WARNING: This task corrects an ECT's historical withdrawal records."
    puts
    puts "Teacher ID: #{teacher.id}"
    puts "TRN: #{teacher.trn}"
    puts "ECT-at-school period ID: #{ect_at_school_period.id}"
    puts "ECT-at-school period dates: " \
         "#{ect_at_school_period.started_on} to " \
         "#{ect_at_school_period.finished_on || 'ongoing'}"
    puts "Corrected end date: #{corrected_end_date}"
    puts

    puts "Original training period:"
    puts "  ID: #{original_training_period.id}"
    puts "  Dates: #{original_training_period.started_on} to " \
         "#{original_training_period.finished_on || 'ongoing'}"
    puts "  Withdrawn at: " \
         "#{original_training_period.withdrawn_at || 'none'}"
    puts "  Withdrawal reason: " \
         "#{original_training_period.withdrawal_reason || 'none'}"
    puts "  Declarations: #{original_training_period.declarations.count}"
    puts "  Events: #{original_training_period.events.count}"
    puts

    puts "Erroneous withdrawn training period:"
    puts "  ID: #{erroneous_withdrawn_training_period.id}"
    puts "  Dates: #{erroneous_withdrawn_training_period.started_on} to " \
         "#{erroneous_withdrawn_training_period.finished_on || 'ongoing'}"
    puts "  Withdrawn at: " \
         "#{erroneous_withdrawn_training_period.withdrawn_at || 'none'}"
    puts "  Withdrawal reason: " \
         "#{erroneous_withdrawn_training_period.withdrawal_reason || 'none'}"
    puts "  Declarations: " \
         "#{erroneous_withdrawn_training_period.declarations.count}"
    puts "  Events: #{erroneous_withdrawn_training_period.events.count}"
    puts

    puts "Action:"
    puts "  - Move the withdrawal details from the erroneous training period"
    puts "  - Apply them to the original training period"
    puts "  - Finish linked records on #{corrected_end_date}"
    puts "  - Remove linked training and mentorship periods starting on or after that date"
    puts "  - Do not record leaving or period-finished events"
    puts

    print "Enter the teacher ID to confirm: "

    unless $stdin.gets&.strip == teacher.id.to_s
      abort "Correction cancelled."
    end

    erroneous_training_period_id =
      erroneous_withdrawn_training_period.id

    Support::ECTWithdrawalHistoryCorrection.new(
      ect_at_school_period:,
      source_training_period: erroneous_withdrawn_training_period,
      target_training_period: original_training_period,
      corrected_finished_on: corrected_end_date,
      author: Events::SystemAuthor.new
    ).correct!

    puts
    puts "Done. Withdrawal history corrected for teacher #{teacher.id}."
    puts
    puts "Updated records:"
    puts "  ECT-at-school period finished on: " \
         "#{ect_at_school_period.reload.finished_on}"
    puts "  Original training period finished on: " \
         "#{original_training_period.reload.finished_on}"
    puts "  Original training period withdrawn at: " \
         "#{original_training_period.withdrawn_at}"
    puts "  Original training period withdrawal reason: " \
         "#{original_training_period.withdrawal_reason}"
    puts "  Erroneous training period removed: " \
         "#{!TrainingPeriod.exists?(erroneous_training_period_id)}"
  end
end
