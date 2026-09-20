# An appropriate body type which after 2023 is led by a specific school
class TeachingSchoolHub < ApplicationRecord
  has_many :appropriate_bodies, class_name: "AppropriateBodyPeriod"

  validates :name, presence: true, uniqueness: true
end
