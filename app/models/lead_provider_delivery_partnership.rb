class LeadProviderDeliveryPartnership < ApplicationRecord
  belongs_to :lead_provider_active_period
  belongs_to :delivery_partner
  has_many :school_partnerships

  validates :lead_provider_active_period, presence: true
  validates :delivery_partner, presence: true
end
