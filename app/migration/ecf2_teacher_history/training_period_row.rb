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
              :withdrawal_reason,
              :created_at,
              :ecf_start_induction_record_id,
              :is_ect

  def initialize(started_on:,
                 finished_on:,
                 created_at:,
                 training_programme:,
                 lead_provider_info: nil,
                 delivery_partner_info: nil,
                 contract_period: nil,
                 schedule_info: nil,
                 deferred_at: nil,
                 deferral_reason: nil,
                 withdrawn_at: nil,
                 withdrawal_reason: nil,
                 ecf_start_induction_record_id: nil,
                 is_ect: false)
    @started_on = started_on
    @finished_on = finished_on
    @created_at = created_at
    @training_programme = training_programme
    @lead_provider_info = lead_provider_info
    @delivery_partner_info = delivery_partner_info
    @contract_period = contract_period
    @schedule_info = schedule_info
    @deferred_at = deferred_at
    @deferral_reason = deferral_reason
    @withdrawn_at = withdrawn_at
    @withdrawal_reason = withdrawal_reason
    @ecf_start_induction_record_id = ecf_start_induction_record_id
    @is_ect = is_ect
  end

  def to_hash
    {
      started_on:,
      finished_on:,
      training_programme:,
      schedule: ecf2_schedule,
      created_at:,
      ecf_start_induction_record_id:
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
    return if schedule_info.blank?

    schedule = Schedule.find_by(contract_period_year: schedule_info.cohort_year, identifier: schedule_info.identifier)

    # ECTs cannot be assigned to replacement schedules
    return nil if schedule&.replacement_schedule? && is_ect

    schedule
  end

  def lead_provider
    return if lead_provider_info.blank?

    LeadProvider.find_by!(ecf_id: lead_provider_info.ecf1_id)
  end

  def delivery_partner
    return if delivery_partner_info.blank?

    DeliveryPartner.find_by!(api_id: delivery_partner_info.ecf1_id)
  end
end
