module GIASHelpers
  extend ActiveSupport::Concern

  included do
    scope :in_gias_schools, -> { includes(:gias_school).references(:gias_schools) }

    scope :currently_open, -> { in_gias_schools.where(gias_school: { status: GIAS::Types::OPEN_STATUSES }) }
    scope :eligible_establishment_type, -> { in_gias_schools.where(gias_school: { type_name: GIAS::Types::ELIGIBLE_TYPES }) }
    scope :in_england, -> { in_gias_schools.where(gias_school: { in_england: true }) }
    scope :section_41, -> { in_gias_schools.where(gias_school: { section_41_approved: true }) }
    scope :eligible, -> { currently_open.eligible_establishment_type.in_england.or(currently_open.in_england.section_41) }
    scope :cip_only, -> { currently_open.where(gias_school: { type_name: GIAS::Types::CIP_ONLY_TYPES }) }
    scope :not_cip_only, -> { where.not(id: cip_only) }
  end

  def independent? = GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.include?(type_name)

  def state_funded? = GIAS::Types::STATE_SCHOOL_TYPES.include?(type_name)
end
