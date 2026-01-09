# NOTE: We currently only associate one TSH with a lead school, we support many
# but may decide not to add these records in the future. If we do, a school can only lead
# up to 3 TSHs.
class TeachingSchoolHub < ApplicationRecord
  # Associations
  belongs_to :dfe_sign_in_organisation
  belongs_to :lead_school, class_name: "School"

  has_many :appropriate_body_periods, class_name: "AppropriateBody"

  # Validations
  validates :name,
            presence: true,
            uniqueness: true

  validate :lead_school_limit

  # Normalizations
  normalizes :name, with: -> { it.squish }

private

  def lead_school_limit
    return unless lead_school

    if lead_school.led_teaching_school_hubs.count >= 3 && !lead_school.led_teaching_school_hubs.exists?(id)
      errors.add(:lead_school, "has reached the maximum of 3 teaching school hubs")
    end
  end
end
