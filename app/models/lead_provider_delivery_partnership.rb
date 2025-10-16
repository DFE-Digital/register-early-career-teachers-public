class LeadProviderDeliveryPartnership < ApplicationRecord
  include DeclarativeUpdates

  belongs_to :active_lead_provider
  belongs_to :delivery_partner
  has_many :school_partnerships
  has_many :events
  has_one :lead_provider, through: :active_lead_provider
  has_one :contract_period, through: :active_lead_provider

  touch -> { delivery_partner }, on_event: %i[create destroy], timestamp_attribute: :api_updated_at
  refresh_metadata -> { delivery_partner }, on_event: %i[create destroy update]

  validates :active_lead_provider_id, presence: {message: "Select an active lead provider"}
  validates :delivery_partner_id,
    presence: {message: "Select a delivery partner"},
    uniqueness: {scope: :active_lead_provider_id, message: "Delivery partner and active lead provider pairing must be unique"}
  validates :ecf_id, uniqueness: {case_sensitive: false}, allow_nil: true

  scope :with_delivery_partner, ->(delivery_partner_id) { where(delivery_partner_id:) }
  scope :with_active_lead_provider, ->(active_lead_provider_id) { where(active_lead_provider_id:) }
  scope :for_contract_period, ->(contract_period) {
    joins(:active_lead_provider)
      .where(active_lead_providers: {contract_period_year: contract_period.year})
      .includes(active_lead_provider: :lead_provider)
  }
  scope :active_lead_provider_ids_for, ->(delivery_partner, contract_period) {
    where(delivery_partner:)
      .joins(:active_lead_provider)
      .where(active_lead_providers: {contract_period_year: contract_period.year})
      .select(:active_lead_provider_id)
  }
end
