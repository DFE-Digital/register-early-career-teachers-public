# Set deferred info on training periods that were migrated without the correct deferral status
#
# $ kubectl exec -it <pod-name> -- bin/rails runner db/scripts/deferred_training_periods.rb
begin
  csv_file = Rails.root.join("db/scripts/deferred_training_periods.csv")
  csv_log = CSV.open(Rails.root.join("tmp/deferred_training_periods_log.csv"), "w")
  csv_log << %w[training_period_id original_started_on original_finished_on deferred_at deferral_reason errors]

  CSV.foreach(csv_file, headers: true, header_converters: :symbol) do |row|
    training_period = TrainingPeriod.find(row[:training_period_id])
    deferred_at = Time.find_zone("UTC").parse(row[:deferred_at])
    deferral_reason = row[:deferral_reason].underscore

    csv_log << [training_period.id, training_period.started_on, training_period.finished_on, deferred_at, deferral_reason, nil]

    MigrationFixes::DeferTrainingPeriod.new(training_period:, deferred_at:, deferral_reason:).defer!

  rescue StandardError => e
    tp_id = row[:training_period_id]
    Rails.logger.warn("ERROR: TrainingPeriod ID: #{tp_id} - #{e.message}")
    csv_log << [tp_id, nil, nil, nil, nil, e.message]
  end
ensure
  csv_log.close unless csv_log.blank?
end
