class Schedule < ApplicationRecord
  MENTOR_TEACHER_TYPE_IDENTIFIERS = %w[
    ecf-replacement-april
    ecf-replacement-january
    ecf-replacement-september
  ].freeze

  enum :identifier,
       {
         'ecf-extended-april' => 'ecf-extended-april',
         'ecf-extended-january' => 'ecf-extended-january',
         'ecf-extended-september' => 'ecf-extended-september',
         'ecf-reduced-april' => 'ecf-reduced-april',
         'ecf-reduced-january' => 'ecf-reduced-january',
         'ecf-reduced-september' => 'ecf-reduced-september',
         'ecf-replacement-april' => 'ecf-replacement-april',
         'ecf-replacement-january' => 'ecf-replacement-january',
         'ecf-replacement-september' => 'ecf-replacement-september',
         'ecf-standard-april' => 'ecf-standard-april',
         'ecf-standard-january' => 'ecf-standard-january',
         'ecf-standard-september' => 'ecf-standard-september'
       },
       validate: { message: 'Choose an identifier from the list' }

  belongs_to :contract_period, inverse_of: :schedules, foreign_key: :contract_period_year
  has_many :milestones
  has_many :training_periods

  validates :contract_period_year,
            presence: { message: 'Enter a contract period year' }

  validates :identifier,
            uniqueness: {
              message: 'Can be used once per contract period',
              scope: :contract_period_year
            }

  def teacher_type
    @teacher_type ||= MENTOR_TEACHER_TYPE_IDENTIFIERS.include?(identifier) ? :mentor : :ect
  end
end
