class RegistrationPeriod < ApplicationRecord
  ECF_FIRST_YEAR = 2020

  # Associations
  has_many :provider_partnerships, inverse_of: :registration_period

  # Validations
  validates :year,
            presence: true,
            uniqueness: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: ECF_FIRST_YEAR,
            }
end
