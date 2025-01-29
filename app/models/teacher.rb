class Teacher < ApplicationRecord
  TRN_FORMAT = %r{\A\d{7}\z}

  self.ignored_columns = %i[search]

  # Associations
  has_many :ect_at_school_periods, inverse_of: :teacher
  has_many :mentor_at_school_periods, inverse_of: :teacher
  has_many :induction_extensions, inverse_of: :teacher
  has_many :induction_periods, -> { order(started_on: :asc) }
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
  scope :search, lambda { |query_string|
    where(
      "teachers.search @@ to_tsquery('unaccented', ?)",
      FullTextSearch::Query.new(query_string).search_by_all_prefixes
    )
  }
end
