# Teaching School Hubs replaced Teaching Schools in 2021.
#
# The majority of hubs do not have concurrent appropriate body providers
# but the few that do typically rebrand themselves as a hub network, alliance or
# similar.
#
class TeachingSchoolHub < ApplicationRecord
  # Hubs became appropriate bodies in 2021 and are ongoing
  APPROPRIATE_BODY = {
    introduced_on: Date.new(2021, 9, 1),
    retired_on: nil,
  }.freeze

  has_many :appropriate_body_periods
  has_many :lead_schools, through: :appropriate_body_periods, source: :lead_schools

  validates :name, presence: true, uniqueness: true
end
