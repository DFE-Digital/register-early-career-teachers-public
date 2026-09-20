class LocalAuthority < ApplicationRecord
  has_one :appropriate_body, class_name: "AppropriateBodyPeriod"

  validates :name, presence: true, uniqueness: true
end
