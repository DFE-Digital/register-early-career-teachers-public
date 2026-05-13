class MigrationFixes::WithdrawTrainingPeriod
  attr_reader :training_period, :withdrawn_at, :withdrawal_reason

  def initialize(training_period:, withdrawn_at:, withdrawal_reason:)
    @training_period = training_period
    @withdrawn_at = withdrawn_at
    @withdrawal_reason = withdrawal_reason
  end

  def withdraw!
    return if training_period.blank?

    if training_period.ongoing?
      training_period.update!(finished_on: withdrawn_at,
                              withdrawn_at:,
                              withdrawal_reason:)
    elsif training_period.withdrawn_at.blank?
      training_period.update!(withdrawn_at: training_period.finished_on,
                              withdrawal_reason:)
    end
  end
end
