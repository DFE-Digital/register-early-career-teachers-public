# Teaching School Hubs replaced Teaching Schools in 2021.
#
# The majority of hubs do not have concurrent appropriate body providers
# but the few that do typically rebrand themselves as a hub network, alliance or
# similar.
#
class TeachingSchoolHub < ApplicationRecord
  has_many :appropriate_bodies, class_name: "AppropriateBodyPeriod"
  has_many :lead_schools, through: :appropriate_bodies, source: :lead_schools

  validates :name, presence: true, uniqueness: true
end
