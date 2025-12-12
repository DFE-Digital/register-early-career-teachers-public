module GIASHelpers
  extend ActiveSupport::Concern

  included do
    scope :in_gias_schools, -> { joins(:gias_school) }
    scope :gias_eligible, -> { in_gias_schools.where(gias_school: { eligible: true }) }
  end

  def independent? = GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.include?(type_name)

  def state_funded? = GIAS::Types::STATE_SCHOOL_TYPES.include?(type_name)
end
