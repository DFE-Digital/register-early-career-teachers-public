class LeadProviderActivePeriod < ApplicationRecord
  belongs_to :lead_provider
  belongs_to :registration_period
  has_many :delivery_partnerships, class_name: "LeadProviderDeliveryPartnership"

  validates :lead_provider, presence: true
  validates :registration_period, presence: true
end
