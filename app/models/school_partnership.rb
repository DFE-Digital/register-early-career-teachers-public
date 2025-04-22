class SchoolPartnership < ApplicationRecord
  belongs_to :lead_provider_delivery_partnership, optional: true
  belongs_to :school

  validates :school, presence: true
end
