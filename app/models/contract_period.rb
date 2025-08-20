class ContractPeriod < ApplicationRecord
  include Interval

  ECF_FIRST_YEAR = 2020

  # Associations
  has_many :active_lead_providers, inverse_of: :contract_period
  has_many :lead_provider_delivery_partnerships, through: :active_lead_providers
  has_many :school_partnerships, through: :lead_provider_delivery_partnerships

  # Scopes
  scope :most_recent_first, -> { order(year: :desc, started_on: :desc) }
  scope :enabled, -> { where(enabled: true) }

  # Validations
  validates :year,
            presence: true,
            uniqueness: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: ECF_FIRST_YEAR,
            }

  validate :no_overlaps
  validates :started_on, presence: { message: "Enter a start date" }
  validates :finished_on, presence: { message: "Enter an end date" }

  def self.containing_date(date)
    find_by(*date_in_range(date))
  end

  def self.earliest_permitted_start_date
    current = containing_date(Time.zone.today)
    return unless current

    current
      .predecessors
      .latest_first
      .offset(1)
      .first
      &.started_on
  end

  def started_on_or_before_today?
    started_on <= Time.zone.today
  end

private

  def siblings
    ContractPeriod.all.excluding(self)
  end

  def no_overlaps
    errors.add(:base, "Contract period overlaps with another contract period") if has_overlap_with_siblings?
  end
end
