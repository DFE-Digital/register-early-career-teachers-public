class InductionExtension < ApplicationRecord
  VALID_NUMBER_OF_TERMS = { min: 0.1, max: 16 }.freeze
  include SharedNumberOfTermsValidation
  belongs_to :teacher
  has_many :events

  validates :number_of_terms, presence: true
end
