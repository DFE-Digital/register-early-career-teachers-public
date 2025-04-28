class LeadProviderDeliveryPartnership < ApplicationRecord
  has_many :school_partnerships
  belongs_to :lead_provider_active_period
  belongs_to :delivery_partner

  validates :lead_provider_active_period, presence: true
  validates :delivery_partner, presence: true
end
