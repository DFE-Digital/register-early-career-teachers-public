class ECF2TeacherHistory::TrainingPeriodRow
  attr_reader :started_on,
              :finished_on,
              :training_programme,
              :lead_provider,
              :delivery_partner,
              :contract_period,
              :schedule,
              :deferred_at,
              :deferral_reason,
              :withdrawn_at,
              :withdrawal_reason

  def initialize(started_on:,
                 finished_on:,
                 training_programme:,
                 lead_provider: nil,
                 delivery_partner: nil,
                 contract_period: nil,
                 schedule: nil,
                 deferred_at: nil,
                 deferral_reason: nil,
                 withdrawn_at: nil,
                 withdrawal_reason: nil)
    @started_on = started_on
    @finished_on = finished_on
    @training_programme = training_programme
    @lead_provider = lead_provider
    @delivery_partner = delivery_partner
    @contract_period = contract_period
    @schedule = schedule
    @deferred_at = deferred_at
    @deferral_reason = deferral_reason
    @withdrawn_at = withdrawn_at
    @withdrawal_reason = withdrawal_reason
  end

  def to_hash
    {
      started_on:,
      finished_on:,
      training_programme:,
      schedule:,
      # FIXME: soon TPs can be both deferred and withdrawn, so this can be uncommented
      # deferred_at:,
      # deferral_reason:,
      # withdrawn_at:,
      # withdrawal_reason:
    }
  end

  def school_partnership(school:)
    SchoolPartnerships::Search.new(school:, contract_period:, lead_provider:, delivery_partner:)
      .school_partnerships
      .first
      .then { |school_partnership| { school_partnership: } }
  end
end
