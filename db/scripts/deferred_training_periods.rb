# Set deferred info on training periods that were migrated without the correct deferral status
#
# $ kubectl exec -it <pod-name> -- bin/rails runner db/scripts/deferred_training_periods.rb

csv_file = Rails.root.join("db/scripts/deferred_training_periods.csv")

CSV.foreach(csv_file, headers: true, header_converters: :symbol) do |row|
  training_period = TrainingPeriod.find(row[:training_period_id])
  deferred_at = Date.parse(row[:deferred_at])
  deferral_reason = row[:deferral_reason].underscore

  MigrationFixes::DeferTrainingPeriod.new(training_period:, deferred_at:, deferral_reason:).defer!
rescue StandardError => e
  Rails.logger.warn("ERROR: TrainingPeriod ID: #{row[:training_period_id]} - #{e.message}")
end
