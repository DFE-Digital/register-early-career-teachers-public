class TeacherHistoryConverter::Cleaner::RemoveRecordsWithMatchingWithdrawnAndDeferredStates
  def initialize(raw_induction_records, states:)
    @raw_induction_records = raw_induction_records
    @states = states
  end

  def induction_records = remove_records_with_withdrawn_and_deferred_states!

private

  def remove_records_with_withdrawn_and_deferred_states!
    states_to_find = @states.find_all { |profile_state| profile_state.state.in? %w[withdrawn deferred] }
    return @raw_induction_records if states_to_find.empty?

    records_to_remove = states_to_find.each_with_object([]) do |profile_state, matching_records|
      # find a matching induction record (unlikely > 1 but handled just in case)
      matching_records.concat(matching_induction_records(profile_state))
    end

    @raw_induction_records - records_to_remove
  end

  # find induction_records that match the profile_state attributes but are not ongoing
  def matching_induction_records(profile_state)
    @raw_induction_records.find_all do |ir|
      ir.end_date.present? &&
        ir.created_at.to_date == profile_state.created_at.to_date &&
        ir.training_status == profile_state.state &&
        ir.training_provider_info&.lead_provider_info&.ecf1_id == profile_state.lead_provider_id
    end
  end
end
