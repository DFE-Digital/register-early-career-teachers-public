class ECF2TeacherHistory::Teacher
  attr_reader :trn,
              :trnless,
              :trs_first_name,
              :trs_last_name,
              :corrected_name,
              :api_id,
              :api_ect_training_record_id,
              :api_mentor_training_record_id,
              :api_updated_at,
              :migration_mode,
              :ect_pupil_premium_uplift,
              :ect_sparsity_uplift,
              :ect_first_became_eligible_for_training_at,
              :ect_payments_frozen_year,
              :mentor_became_ineligible_for_funding_on,
              :mentor_became_ineligible_for_funding_reason,
              :mentor_first_became_eligible_for_training_at,
              :mentor_payments_frozen_year,
              :created_at,
              :updated_at

  def initialize(trn:,
                 trs_first_name:,
                 trs_last_name:,
                 trnless: false,
                 corrected_name: nil,
                 api_id: nil,
                 api_ect_training_record_id: nil,
                 api_mentor_training_record_id: nil,
                 api_updated_at: nil,
                 migration_mode: nil,
                 ect_pupil_premium_uplift: nil,
                 ect_sparsity_uplift: nil,
                 ect_first_became_eligible_for_training_at: nil,
                 ect_payments_frozen_year: nil,
                 mentor_became_ineligible_for_funding_on: nil,
                 mentor_became_ineligible_for_funding_reason: nil,
                 mentor_first_became_eligible_for_training_at: nil,
                 mentor_payments_frozen_year: nil,
                 created_at: nil,
                 updated_at: nil)
    @trn = trn
    @trnless = trnless
    @trs_first_name = trs_first_name
    @trs_last_name = trs_last_name
    @corrected_name = corrected_name
    @api_id = api_id
    @api_ect_training_record_id = api_ect_training_record_id
    @api_mentor_training_record_id = api_mentor_training_record_id
    @api_updated_at = api_updated_at
    @migration_mode = migration_mode
    @ect_pupil_premium_uplift = ect_pupil_premium_uplift
    @ect_sparsity_uplift = ect_sparsity_uplift
    @ect_first_became_eligible_for_training_at = ect_first_became_eligible_for_training_at
    @ect_payments_frozen_year = ect_payments_frozen_year
    @mentor_became_ineligible_for_funding_on = mentor_became_ineligible_for_funding_on
    @mentor_became_ineligible_for_funding_reason = mentor_became_ineligible_for_funding_reason
    @mentor_first_became_eligible_for_training_at = mentor_first_became_eligible_for_training_at
    @mentor_payments_frozen_year = mentor_payments_frozen_year
    @created_at = created_at
    @updated_at = updated_at
  end

  def to_hash
    {
      trn:,
      trs_first_name:,
      trs_last_name:,
      trnless:,
      corrected_name:,

      api_id:,
      api_ect_training_record_id:,
      api_mentor_training_record_id:,
      api_updated_at:,

      migration_mode:,
      ect_pupil_premium_uplift:,
      ect_sparsity_uplift:,
      ect_first_became_eligible_for_training_at:,
      ect_payments_frozen_year:,

      mentor_became_ineligible_for_funding_on:,
      mentor_became_ineligible_for_funding_reason:,
      mentor_first_became_eligible_for_training_at:,
      mentor_payments_frozen_year:,

      created_at:,
      updated_at:
    }.compact
  end
end
