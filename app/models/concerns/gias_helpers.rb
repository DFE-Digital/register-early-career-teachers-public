module GIASHelpers
  extend ActiveSupport::Concern

  included do
    scope :in_gias_schools, -> { joins(:gias_school) }
    scope :eligible, -> { in_gias_schools.where(gias_school: {funding_eligibility: :eligible_for_fip}) }
    scope :cip_only, -> { in_gias_schools.where(gias_school: {funding_eligibility: :eligible_for_cip}) }
    scope :not_cip_only, -> { where.not(id: cip_only) }
  end

  def independent? = GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.include?(type_name)

  def state_funded? = GIAS::Types::STATE_SCHOOL_TYPES.include?(type_name)

  def eligible_for_cip? = funding_eligibility == "eligible_for_cip"

  def eligible_for_fip? = funding_eligibility == "eligible_for_fip"
end
