class MigrationFixes::DeferTrainingPeriod
  attr_reader :training_period, :deferred_at, :deferral_reason

  def initialize(training_period:, deferred_at:, deferral_reason:)
    @training_period = training_period
    @deferred_at = deferred_at
    @deferral_reason = deferral_reason
  end

  def defer!
    return if training_period.blank?

    if training_period.ongoing?
      training_period.assign_attributes(finished_on: deferred_at,
                                        deferred_at:,
                                        deferral_reason:)
    elsif training_period.deferred_at.blank?
      training_period.assign_attributes(deferred_at: training_period.finished_on,
                                        deferral_reason:)
    else
      puts "Not modifying #{training_period.id}"
      return
    end

    # we do not want to modify timestamps
    training_period.save!(touch: false)
  end
end
