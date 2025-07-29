class LeadProviderDeliveryPartnership < ApplicationRecord
  include DeclarativeTouch

  belongs_to :active_lead_provider
  belongs_to :delivery_partner
  has_many :school_partnerships
  has_many :events

  touch -> { delivery_partner }, on_event: %i[create destroy], timestamp_attribute: :api_updated_at

  delegate :lead_provider, :contract_period, to: :active_lead_provider

  validates :active_lead_provider_id, presence: { message: 'Select an active lead provider' }
  validates :delivery_partner_id,
            presence: { message: 'Select a delivery partner' },
            uniqueness: { scope: :active_lead_provider_id, message: 'Delivery partner and active lead provider pairing must be unique' }
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  scope :with_delivery_partner, ->(delivery_partner_id) { where(delivery_partner_id:) }
  scope :with_active_lead_provider, ->(active_lead_provider_id) { where(active_lead_provider_id:) }
end
