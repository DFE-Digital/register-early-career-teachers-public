# Teaching School Hubs replaced Teaching Schools in 2021.
#
# The majority of hubs do not have concurrent appropriate body providers
# but the few that do typically rebrand themselves as a hub network, alliance or
# similar.
#
class TeachingSchoolHub < ApplicationRecord
  ACTED_AS_APPROPRIATE_BODY_DATES = {
    introduced_on: Date.new(2021, 9, 1),
    retired_on: nil,
  }.freeze

  has_many :appropriate_body_periods
  has_many :lead_schools, through: :appropriate_body_periods, source: :lead_schools

  validates :name, presence: true, uniqueness: true

  normalizes :name, with: -> { it.squish }

  # @return [Array<String>]
  def region_codes
    appropriate_body_periods.flat_map do |period|
      period.region_awards.select(&:active?).map { |award| award.region.code }
    end
  end

  def concurrent_appropriate_body_periods?
    appropriate_body_periods.count(&:active?) > 1
  end
end
