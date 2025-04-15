class LeadProvider < ApplicationRecord
  # Associations
  has_many :provider_partnerships, inverse_of: :lead_provider
  has_many :events
  has_many :pending_school_joiners, inverse_of: :lead_provider
  has_many :pending_schools, -> { distinct }, through: :pending_school_joiners, source: :school
  # TODO: this may be better as a scope so we could do something more complex such as exluding records
  #       where a partnership was in place if that was more useful

  # Validations
  validates :name,
            presence: true,
            uniqueness: true
end
