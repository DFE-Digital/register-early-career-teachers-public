class LocalAuthority < ApplicationRecord
  has_one :appropriate_body_period

  validates :name, presence: true, uniqueness: true
end
