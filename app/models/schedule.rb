class Schedule < ApplicationRecord
  enum :identifier,
       %w[
         ecf-standard-january
         ecf-standard-april
         ecf-standard-september
         ecf-extended-january
         ecf-extended-april
         ecf-extended-september
         ecf-reduced-january
         ecf-reduced-april
         ecf-reduced-september
         ecf-replacement-january
         ecf-replacement-april
         ecf-replacement-september
       ].index_by(&:itself),
       validate: { message: "Choose an identifier from the list" }

  REPLACEMENT_SCHEDULE_IDENTIFIERS = identifiers.keys.grep(/replacement/).freeze
  REDUCED_SCHEDULE_IDENTIFIERS = identifiers.keys.grep(/reduced/).freeze

  belongs_to :contract_period, inverse_of: :schedules, foreign_key: :contract_period_year
  has_many :milestones
  has_many :training_periods

  validates :contract_period_year,
            presence: { message: "Enter a contract period year" }

  validates :identifier,
            uniqueness: {
              message: "Can be used once per contract period",
              scope: :contract_period_year
            }

  scope :excluding_replacement_schedules, -> {
    where.not(identifier: REPLACEMENT_SCHEDULE_IDENTIFIERS)
  }

  scope :excluding_reduced_schedules, -> {
    where.not(identifier: REDUCED_SCHEDULE_IDENTIFIERS)
  }

  def replacement_schedule?
    identifier.in?(REPLACEMENT_SCHEDULE_IDENTIFIERS)
  end

  def reduced_schedule?
    identifier.in?(REDUCED_SCHEDULE_IDENTIFIERS)
  end

  def description
    "#{identifier} for #{contract_period.year}"
  end
end
