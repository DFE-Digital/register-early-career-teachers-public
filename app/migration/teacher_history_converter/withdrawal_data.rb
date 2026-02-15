class TeacherHistoryConverter::WithdrawalData
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

  def withdrawal_data
    return {} if cpd_lead_provider_id.blank?
    return {} unless training_status == "withdrawn"
    return {} unless states.any?

    # here, we want to find the relevant state from the ECT so the withdrawal reason/timestamp
    # are populated, but there are multiple approaches
    #
    # The most obvious would be to find the state that's 'within' the induction period, like this:
    #
    # if (matching_state = states.find { it.created_at.in?(induction_record_start.to_date..induction_record_end&.to_date) })
    #
    # but sometimes the withdrawal happened earlier, and ECF1 takes care of this by searching for the most recent
    # withdrawal event for the teacher
    #
    # In ECF1 we're also finding the most recent 'withdrawn' profile state
    #
    # https://github.com/DFE-Digital/early-careers-framework/blob/main/app/serializers/api/v3/ecf/participant_serializer.rb#L37-L41

    return {} unless (matching_state = states.find { it.state == "withdrawn" && it.cpd_lead_provider_id == cpd_lead_provider_id })

    {
      withdrawal_reason: matching_state.reason.to_s,
      withdrawn_at: matching_state.created_at
    }
  end
end
