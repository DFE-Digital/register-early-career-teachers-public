class ECF2TeacherHistory::TrainingPeriodRow
  attr_reader :started_on,
              :finished_on,
              :training_programme,
              :lead_provider_info,
              :delivery_partner_info,
              :contract_period,
              :schedule_info,
              :deferred_at,
              :deferral_reason,
              :withdrawn_at,
              :withdrawal_reason

  def initialize(started_on:,
                 finished_on:,
                 training_programme:,
                 lead_provider_info: nil,
                 delivery_partner_info: nil,
                 contract_period: nil,
                 schedule_info: nil,
                 deferred_at: nil,
                 deferral_reason: nil,
                 withdrawn_at: nil,
                 withdrawal_reason: nil)
    @started_on = started_on
    @finished_on = finished_on
    @training_programme = training_programme
    @lead_provider_info = lead_provider_info
    @delivery_partner_info = delivery_partner_info
    @contract_period = contract_period
    @schedule_info = schedule_info
    # FIXME: rename schedule_info? We could probably do with a convention here
    #        to differentiate between ecf1 records, ecf2 records and the data objects
    #        we're using for migration
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
      schedule: ecf2_schedule,
      # FIXME: soon TPs can be both deferred and withdrawn, so this can be uncommented
      # deferred_at:,
      # deferral_reason:,
      # withdrawn_at:,
      # withdrawal_reason:
    }
  end

  # FIXME: the school here is from one level up, perhaps there's a nicer way of cross-referencing?
  def school_partnership(school:)
    SchoolPartnerships::Search.new(school:, contract_period:, lead_provider:, delivery_partner:)
      .school_partnerships
      .first
      .then { |school_partnership| { school_partnership: } }
  end

  def ecf2_schedule
    return unless schedule_info.present?

    Schedule.find_by(contract_period_year: schedule_info.cohort_year, identifier: schedule_info.identifier)
  end

  def lead_provider
    return unless lead_provider_info.present?

    LeadProvider.find_by!(ecf_id: lead_provider_info.id)
  end

  def delivery_partner
    return unless delivery_partner_info.present?

    DeliveryPartner.find_by!(api_id: delivery_partner_info.id)
  end
end
