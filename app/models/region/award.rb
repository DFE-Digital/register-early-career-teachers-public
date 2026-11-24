class Region::Award < ApplicationRecord
  belongs_to :appropriate_body_period, inverse_of: :region_awards
  belongs_to :lead_school,
             class_name: "School",
             inverse_of: :region_awards
  belongs_to :region,
             inverse_of: :awards

  scope :active, -> { where(deactivated_at: nil) }
  scope :excluding_lead_school, ->(lead_school) { where.not(lead_school:) }

  validates :appropriate_body_period, :lead_school, :region, presence: true
  validates :region_id,
            uniqueness: {
              scope: :appropriate_body_period_id,
              conditions: -> { active },
              message: "is already linked to this appropriate body"
            },
            if: :active?
  validate :region_is_not_held_by_another_school, if: :active?

  def active? = deactivated_at.nil?

  def lead_school_is_the_provisioner? = lead_school.eql?(appropriate_body_period.provisioning_school)

  def other_awards_for_region = region.active_awards.excluding(self)

  def other_lead_schools = School.where(id: other_awards_for_region.select(:lead_school_id))

private

  def region_is_not_held_by_another_school
    return if region.blank? || lead_school.blank?
    return if region.active_awards.excluding_lead_school(lead_school).excluding(self).none?

    errors.add(:region_id, "is already awarded to #{other_lead_schools.first.name}")
  end
end
