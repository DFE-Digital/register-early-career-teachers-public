class TeacherHistoryConverter::PremiumWithdrawalData
  attr_reader :state_changed_at, :states, :lead_provider_id

  def initialize(state_changed_at:, states:, lead_provider_id:)
    @state_changed_at = state_changed_at
    @lead_provider_id = lead_provider_id
    @states = states
  end

  def withdrawal_data
    return {} if state_changed_at.blank?
    return {} if lead_provider_id.blank?
    return {} if states.blank?
    return {} if matching_state.blank?

    {
      withdrawal_reason: ecf2_reason(matching_state.reason.to_s),
      withdrawn_at: matching_state.created_at
    }
  end

  def matching_state
    # in PREMIUM mode we remove any 'withdrawn' training_status induction records that correspond to a withdrawn
    # `ParticipantProfileState` so we match against the previous induction record's end_date as the withdrawal
    # caused the change in the induction record.
    # So here we're searching for a withdrawn state that occurred on the same day as the state_changed_at param
    # (which is the end_date of the previous induction record) for the same lead provider.
    # In the unlikely event of multiple matching state records, grab the most recent.
    @matching_state ||= states.select { |profile_state|
      profile_state.state == "withdrawn" &&
        profile_state.lead_provider_id == lead_provider_id &&
        profile_state.created_on == state_changed_at.to_date
    }.max_by(&:created_at)
  end

  delegate :ecf2_reason, to: :'Mappers::WithdrawalReasonMapper'
end
