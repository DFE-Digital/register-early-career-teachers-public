class LeadProvider < ApplicationRecord
  include DeclarativeUpdates

  # Associations
  has_many :framework_agreements, inverse_of: :lead_provider
  has_many :lead_provider_delivery_partnerships, through: :framework_agreements
  has_many :school_partnerships, through: :lead_provider_delivery_partnerships
  has_many :training_periods, through: :school_partnerships
  has_many :declarations, through: :training_periods
  has_many :events
  has_many :api_tokens, class_name: "API::Token"

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true
  validates :vat_registered, inclusion: [true, false]
  validates :short_name, presence: true, uniqueness: { case_sensitive: false }

  scope :alphabetical, -> { order(name: :asc) }

  normalizes :name, with: -> { it.squish }
  normalizes :short_name, with: -> { it.squish.downcase }

  touch -> { training_periods }, when_changing: %i[name], timestamp_attribute: :api_transfer_updated_at

  def name=(name)
    super

    assign_short_name
  end

  def assign_short_name
    return if name.blank?

    self.short_name = if name.include?(" ")
                        name.split.map(&:first).join
                      else
                        name
                      end
  end
end
