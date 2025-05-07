class RegistrationPeriod < ApplicationRecord
  include Interval

  ECF_FIRST_YEAR = 2020

  # Associations
  has_many :lead_provider_active_periods

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

private

  def siblings
    RegistrationPeriod.all.excluding(self)
  end

  def no_overlaps
    errors.add(:base, "Registration period overlaps with another registration period") if has_overlap_with_siblings?
  end
end
