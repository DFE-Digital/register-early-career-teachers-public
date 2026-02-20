class ContractPeriod < ApplicationRecord
  include Interval

  ECF_FIRST_YEAR = 2020

  # Associations
  has_many :active_lead_providers, inverse_of: :contract_period
  has_many :schedules, inverse_of: :contract_period
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
  validates :mentor_funding_enabled,
            :detailed_evidence_types_enabled, inclusion: { in: [true, false] }

  def self.containing_date(date)
    find_by(*date_in_range(date))
  end

  def self.containing_date_end_inclusive(date)
    find_by(*date_in_range_inclusive_start_inclusive_end(date))
  end

  def self.current
    containing_date(Time.zone.today)
  end

  def self.current_end_inclusive
    containing_date_end_inclusive(Time.zone.today)
  end

  def self.earliest_permitted_start_date
    return unless current_end_inclusive

    current_end_inclusive
      .predecessors
      .latest_first
      .offset(1)
      .first
      &.started_on
  end

  def self.for_registration_start_date(start_date)
    current_contract_period = current
    return current_contract_period unless current_contract_period && start_date.is_a?(Date)

    contract_period_from_start_date = containing_date(start_date)
    return current_contract_period if contract_period_from_start_date.nil?
    return current_contract_period if contract_period_from_start_date.year < current_contract_period.year

    contract_period_from_start_date
  end

  def started_on_or_before_today?
    started_on <= Time.zone.today
  end

  def payments_frozen?
    payments_frozen_at.present? && payments_frozen_at <= Time.zone.now
  end

private

  def siblings
    ContractPeriod.all.excluding(self)
  end

  def no_overlaps
    errors.add(:base, "Contract period overlaps with another contract period") if has_overlap_with_siblings?
  end
end
