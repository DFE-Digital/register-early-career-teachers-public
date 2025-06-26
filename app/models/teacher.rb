class Teacher < ApplicationRecord
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
  has_many :induction_periods
  has_many :appropriate_bodies, through: :induction_periods
  has_many :events

  # TODO: remove after migration complete
  has_many :teacher_migration_failures

  # Validations
  validates :trn,
            uniqueness: { message: 'TRN already exists', case_sensitive: false },
            teacher_reference_number: true

  validates :trs_induction_status,
            allow_nil: true,
            length: { maximum: 18, message: 'TRS induction status must be shorter than 18 characters' }

  validates :mentor_became_ineligible_for_funding_on,
            presence: { message: 'Enter the date when the mentor became ineligible for funding' },
            if: -> { mentor_became_ineligible_for_funding_reason.present? }
  validates :mentor_became_ineligible_for_funding_reason,
            presence: { message: 'Choose the reason why the mentor became ineligible for funding' },
            if: -> { mentor_became_ineligible_for_funding_on.present? }

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
end
