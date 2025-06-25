class RegistrationPeriod < ApplicationRecord
  include Interval

  ECF_FIRST_YEAR = 2020

  # Associations
  has_many :active_lead_providers, inverse_of: :registration_period
  has_many :lead_provider_delivery_partnerships, through: :active_lead_providers
  has_many :school_partnerships, through: :lead_provider_delivery_partnerships

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

  def self.for_date(date)
    where('range @> ?::date', date).first
  end

private

  def siblings
    RegistrationPeriod.all.excluding(self)
  end

  def no_overlaps
    errors.add(:base, "Registration period overlaps with another registration period") if has_overlap_with_siblings?
  end
end
