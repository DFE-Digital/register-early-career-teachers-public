class ECF2TeacherHistory::TrainingPeriod
  attr_reader :started_on,
              :training_programme,
              :lead_provider_info,
              :delivery_partner_info,
              :contract_period_year,
              :schedule_info,
              :deferred_at,
              :deferral_reason,
              :withdrawn_at,
              :withdrawal_reason,
              :created_at,
              :ecf_start_induction_record_id,
              :is_ect,
              :school

  attr_accessor :finished_on

  def initialize(started_on:,
                 finished_on:,
                 created_at:,
                 training_programme:,
                 lead_provider_info: nil,
                 delivery_partner_info: nil,
                 contract_period_year: nil,
                 schedule_info: nil,
                 deferred_at: nil,
                 deferral_reason: nil,
                 withdrawn_at: nil,
                 withdrawal_reason: nil,
                 ecf_start_induction_record_id: nil,
                 is_ect: false,
                 school: nil)
    @started_on = started_on
    @finished_on = finished_on
    @created_at = created_at
    @training_programme = training_programme
    @lead_provider_info = lead_provider_info
    @delivery_partner_info = delivery_partner_info
    @contract_period_year = contract_period_year
    @schedule_info = schedule_info
    @deferred_at = deferred_at
    @deferral_reason = deferral_reason
    @withdrawn_at = withdrawn_at
    @withdrawal_reason = withdrawal_reason
    @ecf_start_induction_record_id = ecf_start_induction_record_id
    @is_ect = is_ect
    @school = school
  end

  def combination
    [school.urn, contract_period_year, lead_provider_info&.name].join(": ")
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

  def to_h
    {
      started_on:,
      finished_on:,
      training_programme:,
      schedule: schedule_info,
      created_at:,
      ecf_start_induction_record_id:,
      lead_provider_info: lead_provider_info.to_h,
      delivery_partner_info: delivery_partner_info.to_h,
      contract_period_year:
    }
  end

  def school_partnership
    validate_active_lead_provider_exists!
    validate_lead_provider_delivery_partnership_exists!

    partnership = SchoolPartnerships::Search.new(school: school.ecf2_school, contract_period: contract_period_year, lead_provider:, delivery_partner:)
      .school_partnerships
      .first

    if partnership.nil?
      raise ActiveRecord::RecordNotFound, "No SchoolPartnership found for training period"
    end

    { school_partnership: partnership }
  end

  def validate_active_lead_provider_exists!
    return if lead_provider.nil?

    active_lead_provider = ActiveLeadProvider.find_by(lead_provider:, contract_period_year:)
    if active_lead_provider.nil?
      raise ActiveRecord::RecordNotFound,
            "No ActiveLeadProvider found for lead_provider_id #{lead_provider.id} and contract_period_year #{contract_period_year}"
    end
  end

  def validate_lead_provider_delivery_partnership_exists!
    return if lead_provider.nil? || delivery_partner.nil?

    active_lead_provider = ActiveLeadProvider.find_by(lead_provider:, contract_period_year:)
    return if active_lead_provider.nil?

    lead_provider_delivery_partnership = LeadProviderDeliveryPartnership.find_by(active_lead_provider:, delivery_partner:)
    if lead_provider_delivery_partnership.nil?
      raise ActiveRecord::RecordNotFound,
            "No LeadProviderDeliveryPartnership found for active_lead_provider_id #{active_lead_provider.id} and delivery_partner_id #{delivery_partner.id}"
    end
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
