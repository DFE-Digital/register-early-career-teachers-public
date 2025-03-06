class Teacher < ApplicationRecord
  TRN_FORMAT = %r{\A\d{7}\z}

  self.ignored_columns = %i[search]

  enum :mentor_completion_reason, {
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
  validates :trs_first_name,
            presence: true

  validates :trs_last_name,
            presence: true

  validates :trn,
            uniqueness: { message: 'TRN already exists', case_sensitive: false },
            teacher_reference_number: true

  # Scopes
  scope :search, ->(query_string) {
    where(
      "teachers.search @@ to_tsquery('unaccented', ?)",
      FullTextSearch::Query.new(query_string).search_by_all_prefixes
    )
  }

  # Instance methods
  def eligible_for_mentor_funding?
    mentor_completion_date.blank? && mentor_completion_reason.blank?
  end

  def ineligible_for_mentor_funding?
    !eligible_for_mentor_funding?
  end
end
