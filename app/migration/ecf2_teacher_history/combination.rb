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
  def summary = [school_urn, cohort_year, lead_provider_name].join(": ")
end
