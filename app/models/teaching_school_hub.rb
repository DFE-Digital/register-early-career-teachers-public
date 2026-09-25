class TeachingSchoolHub < ApplicationRecord
  has_many :appropriate_bodies, class_name: "AppropriateBodyPeriod"
  has_many :lead_schools, through: :appropriate_bodies, source: :lead_schools

  validates :name, presence: true, uniqueness: true
end
