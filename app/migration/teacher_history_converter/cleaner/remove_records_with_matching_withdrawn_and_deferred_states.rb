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

    records_to_remove = []

    states_to_find.each do |profile_state|
      # find a matching induction record
      induction_record = @raw_induction_records.find do |ir|
        ir.created_at.to_date == profile_state.created_at.to_date &&
          ir.training_status == profile_state.state &&
          ir.training_provider_info&.lead_provider_info&.ecf1_id == lead_provider_id(profile_state.cpd_lead_provider_id)
      end

      records_to_remove << induction_record if induction_record.present?
    end

    @raw_induction_records - records_to_remove
  end

  def lead_provider_id(cpd_lead_provider_id)
    Mappers::LeadProviderMapper.new(index_by: :cpd_lead_provider_id).get(cpd_lead_provider_id)&.id
  end
end
