class Region < ApplicationRecord
  belongs_to :teaching_school_hub

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :districts, presence: true
  validate :region_limit, if: -> { teaching_school_hub.present? }

  def region_limit
    if teaching_school_hub.regions.count >= 3
      errors.add(:teaching_school_hub, "#{teaching_school_hub.name} already has the maximum of 3 hub regions")
    end
  end
end
