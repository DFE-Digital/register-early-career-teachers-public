class LeadProvider < ApplicationRecord
  # Associations
  has_many :active_lead_providers, inverse_of: :lead_provider
  has_many :lead_provider_delivery_partnerships, through: :active_lead_providers
  has_many :events
  has_many :api_tokens, class_name: "API::Token"

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  scope :alphabetical, -> { order(name: :asc) }
end
