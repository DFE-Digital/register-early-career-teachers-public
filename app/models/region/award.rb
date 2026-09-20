class Region::Award < ApplicationRecord
  belongs_to :appropriate_body_period, inverse_of: :region_awards

  belongs_to :school,
             inverse_of: :region_awards
  belongs_to :region,
             inverse_of: :awards

  scope :active, -> { where(deactivated_at: nil) }

  validates :appropriate_body_period, :school, :region, presence: true

  validates :region_id,
            uniqueness: {
              conditions: -> { active },
              message: "is already linked to an active lead school"
            }

  validates :region_id,
            uniqueness: {
              scope: :appropriate_body_period_id,
              conditions: -> { active },
              message: "is already linked to this appropriate body"
            }

  def active? = deactivated_at.nil?
end
