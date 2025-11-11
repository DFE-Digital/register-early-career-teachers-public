class Teacher < ApplicationRecord
  include DeclarativeUpdates

  TRN_FORMAT = %r{\A\d{7}\z}

  self.ignored_columns = %i[search]

  enum :mentor_became_ineligible_for_funding_reason, {
    completed_declaration_received: 'completed_declaration_received',
    completed_during_early_roll_out: 'completed_during_early_roll_out',
    started_not_completed: 'started_not_completed',
  }

  # Associations
  has_many :ect_at_school_periods, inverse_of: :teacher
  has_many :mentor_at_school_periods, inverse_of: :teacher
  has_many :induction_extensions, inverse_of: :teacher
  has_many :teacher_id_changes, inverse_of: :teacher
  has_many :lead_provider_metadata, class_name: "Metadata::TeacherLeadProvider"
  has_many :induction_periods
  has_one :first_induction_period, -> { order(started_on: :asc) }, class_name: "InductionPeriod"
  has_one :last_induction_period, -> { order(started_on: :desc) }, class_name: "InductionPeriod"
  has_one :ongoing_induction_period, -> { ongoing }, class_name: "InductionPeriod"
  has_one :started_induction_period, -> { earliest_first }, class_name: "InductionPeriod"
  has_one :finished_induction_period, -> { finished.with_outcome.latest_first }, class_name: "InductionPeriod"
  has_one :earliest_ect_at_school_period, -> { earliest_first }, class_name: "ECTAtSchoolPeriod"
  has_one :earliest_mentor_at_school_period, -> { earliest_first }, class_name: "MentorAtSchoolPeriod"
  has_many :appropriate_bodies, through: :induction_periods
  has_one :current_appropriate_body, through: :ongoing_induction_period, source: :appropriate_body
  has_one :current_or_next_ect_at_school_period, -> { current_or_future.earliest_first }, class_name: 'ECTAtSchoolPeriod'
  has_one :latest_mentor_at_school_period, -> { latest_first }, class_name: 'MentorAtSchoolPeriod'
  has_many :events

  # TODO: remove after migration complete
  has_many :teacher_migration_failures

  touch -> { self },
        on_event: :update,
        timestamp_attribute: :api_updated_at,
        when_changing: %i[
          api_id
          trs_first_name
          trs_last_name
          trn
          api_ect_training_record_id
          api_mentor_training_record_id
          mentor_became_ineligible_for_funding_on
          mentor_became_ineligible_for_funding_reason
          ect_first_became_eligible_for_training_at
          mentor_first_became_eligible_for_training_at
          ect_pupil_premium_uplift
          ect_sparsity_uplift
          ect_payments_frozen_year
          mentor_payments_frozen_year
        ]

  refresh_metadata -> { self }, on_event: %i[create update]

  # Validations
  validates :trn,
            uniqueness: { message: 'TRN already exists', case_sensitive: false, allow_nil: true },
            teacher_reference_number: true,
            presence: { message: 'Enter the teacher reference number (TRN)' },
            unless: :trnless?

  validates :trn,
            absence: { message: 'TRN not allowed when trnless is true' },
            if: :trnless?

  validates :trs_induction_status,
            allow_nil: true,
            length: { maximum: 18, message: 'TRS induction status must be shorter than 18 characters' }

  validates :mentor_became_ineligible_for_funding_on,
            presence: { message: 'Enter the date when the mentor became ineligible for funding' },
            if: -> { mentor_became_ineligible_for_funding_reason.present? }
  validates :mentor_became_ineligible_for_funding_reason,
            presence: { message: 'Choose the reason why the mentor became ineligible for funding' },
            if: -> { mentor_became_ineligible_for_funding_on.present? }
  validates :api_id, uniqueness: { case_sensitive: false, message: "API id already exists for another teacher" }
  validates :api_ect_training_record_id, uniqueness: { case_sensitive: false, message: "API ect training record id already exists for another teacher" }, allow_nil: true
  validates :api_mentor_training_record_id, uniqueness: { case_sensitive: false, message: "API mentor training record id already exists for another teacher" }, allow_nil: true
  validates :ect_first_became_eligible_for_training_at, immutable_once_set: true
  validates :mentor_first_became_eligible_for_training_at, immutable_once_set: true

  # Scopes
  scope :search, ->(query_string) {
    where(
      "teachers.search @@ to_tsquery('unaccented', ?)",
      FullTextSearch::Query.new(query_string).search_by_all_prefixes
    )
  }

  scope :ordered_by_trs_data_last_refreshed_at_nulls_first, -> {
    order(arel_table[:trs_data_last_refreshed_at].asc.nulls_first)
  }

  scope :deactivated_in_trs, -> { where(trs_deactivated: true) }
  scope :active_in_trs, -> { where(trs_deactivated: false) }

  normalizes :corrected_name, with: -> { it.squish }
end
