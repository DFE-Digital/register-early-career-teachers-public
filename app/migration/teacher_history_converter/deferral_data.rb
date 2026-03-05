class TeacherHistoryConverter::DeferralData
  attr_reader :training_status, :states, :lead_provider_id

  def initialize(training_status:, states:, lead_provider_id:)
    @training_status = training_status
    @states = states.sort_by(&:created_at).reverse
    @lead_provider_id = lead_provider_id
  end

  def cpd_lead_provider_id
    return if lead_provider_id.nil?

    Mappers::LeadProviderMapper.new(index_by: :id).get(lead_provider_id)&.cpd_lead_provider_id
  end

  def deferral_data
    return {} if cpd_lead_provider_id.blank?
    return {} unless training_status == "deferred"
    return {} unless states.any?

    # here, we want to find the relevant state from the ECT so the deferral reason/timestamp
    # are populated, but there are multiple approaches
    #
    # The most obvious would be to find the state that's 'within' the induction period, like this:
    #
    # if (matching_state = states.find { it.created_at.in?(induction_record_start.to_date..induction_record_end&.to_date) })
    #
    # but sometimes the deferral happened earlier, and ECF1 takes care of this by searching for the most recent
    # deferral event for the teacher
    #
    # In ECF1 we're also finding the most recent 'deferred' profile state
    #
    # https://github.com/DFE-Digital/early-careers-framework/blob/main/app/serializers/api/v3/ecf/participant_serializer.rb#L37-L41

    return {} unless (matching_state = states.find { it.state == "deferred" && it.cpd_lead_provider_id == cpd_lead_provider_id })

    {
      deferral_reason: ecf2_reason(matching_state.reason.to_s),
      deferred_at: matching_state.created_at
    }
  end

  def ecf2_reason(ecf1_reason)
    # ECF1 reasons:
    # * bereavement
    # * career-break
    # * long-term-sickness
    # * parental-leave
    # * other
    # * (null)
    #
    # ECF2 reasons:
    # * bereavement
    # * career_break
    # * long_term_sickness
    # * parental_leave
    # * other
    case ecf1_reason
    when "bereavement" then "bereavement"
    when "career-break" then "career_break"
    when "long-term-sickness" then "long_term_sickness"
    when "parental-leave" then "parental_leave"
    else "other"
    end
  end
end
