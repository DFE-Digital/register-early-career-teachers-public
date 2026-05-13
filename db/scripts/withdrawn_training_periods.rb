# Set withdrawal info on training periods that were migrated without the correct withdrawal status
#
# $ kubectl exec -it <pod-name> -- bin/rails runner db/scripts/withdrawn_training_periods.rb
begin
  csv_file = Rails.root.join("db/scripts/withdrawn_training_periods.csv")
  csv_log = CSV.open(Rails.root.join("tmp/withdrawn_training_periods_log.csv"), "w")
  csv_log << %w[training_period_id original_started_on original_finished_on original_deferred_at original_deferral_reason original_withdrawn_at original_withdrawal_reason withdrawn_at withdrawal_reason errors]

  CSV.foreach(csv_file, headers: true, header_converters: :symbol) do |row|
    training_period = TrainingPeriod.find(row[:training_period_id])
    withdrawn_at = Time.find_zone("UTC").parse(row[:withdrawn_at])
    withdrawal_reason = row[:withdrawal_reason].underscore

    csv_log << [training_period.id, training_period.started_on, training_period.finished_on, training_period.deferred_at, training_period.deferral_reason, training_period.withdrawn_at, training_period.withdrawal_reason, withdrawn_at, withdrawal_reason, nil]

    MigrationFixes::WithdrawTrainingPeriod.new(training_period:, withdrawn_at:, withdrawal_reason:).withdraw!
  rescue StandardError => e
    tp_id = row[:training_period_id]
    Rails.logger.warn("ERROR: TrainingPeriod ID: #{tp_id} - #{e.message}")
    csv_log << [tp_id, nil, nil, nil, nil, nil, nil, nil, nil, e.message]
  end
ensure
  (csv_log.presence&.close)
end
