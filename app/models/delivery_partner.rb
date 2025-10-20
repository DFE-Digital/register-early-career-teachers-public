class DeliveryPartner < ApplicationRecord
  include DeclarativeUpdates

  # Associations
  has_many :lead_provider_delivery_partnerships, inverse_of: :delivery_partner
  has_many :school_partnerships, through: :lead_provider_delivery_partnerships
  has_many :events
  has_many :lead_provider_metadata, class_name: "Metadata::DeliveryPartnerLeadProvider"

  refresh_metadata -> { self }, on_event: %i[create]

  # Validations
  validates :name,
    uniqueness: {case_sensitive: false,
                 message: "A delivery partner with this name already exists"}

  validates :name,
    presence: true,
    unless: -> { validation_context == :rename }

  validates :name,
    presence: {message: ->(dp, _) { "Enter the new name for #{dp.name_was || dp.name}" }},
    on: :rename

  validates :api_id,
    uniqueness: {case_sensitive: false, message: "API id already exists for another delivery partner"}

  touch -> { self }, when_changing: %i[name], timestamp_attribute: :api_updated_at
  touch -> { school_partnerships }, when_changing: %i[name], timestamp_attribute: :api_updated_at

  normalizes :name, with: -> { it.squish }
end
