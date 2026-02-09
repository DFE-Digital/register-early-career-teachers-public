ECF2TeacherHistory::Combination = Struct.new(
  :trn,
  :profile_id,
  :profile_type,
  :induction_record_id,
  :training_programme,
  :school_urn,
  :cohort_year,
  :lead_provider_name,
  :delivery_partner_name,
  :start_date,
  :end_date,
  :induction_status,
  :training_status,
  :mentor_profile_id,
  :schedule_id,
  :schedule_identifier,
  :schedule_name,
  :schedule_cohort_year,
  :preferred_identity_email,
  :created_at,
  :updated_at,
  keyword_init: true
) do
  def summary = "<#{[induction_record_id, school_urn, cohort_year, lead_provider_name].join(': ')}>"

  def self.from_induction_record(trn:, profile_id:, profile_type:, induction_record:, **overrides)
    new(
      trn:,
      profile_id:,
      profile_type:,
      induction_record_id: induction_record.induction_record_id,
      training_programme: induction_record.training_programme,
      school_urn: induction_record.school.urn,
      cohort_year: induction_record.cohort_year,
      lead_provider_name: induction_record.training_provider_info&.lead_provider_info&.name,
      delivery_partner_name: induction_record.training_provider_info&.delivery_partner_info&.name,
      start_date: induction_record.start_date,
      end_date: induction_record.end_date,
      induction_status: induction_record.induction_status,
      training_status: induction_record.training_status,
      mentor_profile_id: induction_record.mentor_profile_id,
      schedule_id: induction_record.schedule_info&.schedule_id,
      schedule_identifier: induction_record.schedule_info&.identifier,
      schedule_name: induction_record.schedule_info&.name,
      schedule_cohort_year: induction_record.schedule_info&.cohort_year,
      preferred_identity_email: induction_record.preferred_identity_email,
      created_at: induction_record.created_at,
      updated_at: induction_record.updated_at,
      **overrides
    ).tap do |combination|
      combination.lead_provider_name = "school_led" if combination.training_programme.to_s == "school_led"
    end
  end
end
