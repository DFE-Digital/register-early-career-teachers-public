class LocalAuthority < ApplicationRecord
  # Local authorities acted as appropriate bodies between these dates.
  APPROPRIATE_BODY = {
    introduced_on: Date.new(2012, 8, 31),
    retired_on: Date.new(2023, 9, 1),
  }.freeze

  has_one :appropriate_body_period

  validates :name, presence: true, uniqueness: true
end
