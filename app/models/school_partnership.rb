class SchoolPartnership < ApplicationRecord
  belongs_to :lead_provider_delivery_partnership, optional: true
  belongs_to :school
  has_many :training_periods, inverse_of: :confirmed_school_partnership

  validates :school, presence: true
end
