# Data from OmniAuth responses from DfE Sign-In
class DfESignInOrganisation < ApplicationRecord
  # Associations
  # TODO: remove appropriate_body_period when dfe_sign_in_organisation_id is removed from AppropriateBody
  has_one :appropriate_body_period,
          class_name: "AppropriateBody",
          foreign_key: :dfe_sign_in_organisation_id,
          primary_key: :uuid,
          inverse_of: :dfe_sign_in_organisation

  has_one :school,
          foreign_key: :urn,
          primary_key: :urn

  has_one :national_body

  # Validations
  validates :name,
            presence: true,
            uniqueness: true

  validates :uuid,
            presence: true,
            uniqueness: true

  # Scopes
  scope :national_bodies, -> { joins(:national_body) }
  scope :schools, -> { includes(:school).where.not(urn: nil) }

  def last_authenticated_at=(datetime)
    self.first_authenticated_at ||= datetime
    super
  end
end
