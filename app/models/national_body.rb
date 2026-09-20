class NationalBody < ApplicationRecord
  has_many :appropriate_bodies, class_name: "AppropriateBodyPeriod"

  validates :name, presence: true, uniqueness: true
end
