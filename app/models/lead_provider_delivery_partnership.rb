class LeadProviderDeliveryPartnership < ApplicationRecord
  include DeclarativeUpdates

  belongs_to :framework_agreement
  belongs_to :delivery_partner
  has_many :school_partnerships
  has_many :events, dependent: :nullify
  has_one :lead_provider, through: :framework_agreement
  has_one :contract_period, through: :framework_agreement

  delegate :name, to: :delivery_partner, prefix: true

  touch -> { delivery_partner }, on_event: %i[create destroy], timestamp_attribute: :api_updated_at

  validates :framework_agreement_id, presence: { message: "Select a lead provider framework agreement" }
  validates :delivery_partner_id,
            presence: { message: "Select a delivery partner" },
            uniqueness: { scope: :framework_agreement_id, message: "Delivery partner and lead provider framework agreement pairing must be unique" }
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  scope :with_delivery_partner, ->(delivery_partner_id) { where(delivery_partner_id:) }
  scope :with_framework_agreement, ->(framework_agreement_id) { where(framework_agreement_id:) }
  scope :for_contract_period, ->(contract_period) {
    joins(:framework_agreement)
      .where(framework_agreements: { contract_period_year: contract_period.year })
      .includes(framework_agreement: :lead_provider)
  }
  scope :framework_agreement_ids_for, ->(delivery_partner, contract_period) {
    where(delivery_partner:)
      .joins(:framework_agreement)
      .where(framework_agreements: { contract_period_year: contract_period.year })
      .select(:framework_agreement_id)
  }
end
