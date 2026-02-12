class TeachingSchoolHub < ApplicationRecord
  # Associations
  belongs_to :dfe_sign_in_organisation
  belongs_to :lead_school, class_name: "School"

  has_many :appropriate_body_periods
  has_many :regions

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :lead_school, presence: true, uniqueness: true
  validates :dfe_sign_in_organisation, presence: true, uniqueness: true

  # Normalizations
  normalizes :name, with: -> { it.squish }

  # @return [Array<String>]
  def districts
    regions.collect(&:districts).flatten
  end
end
