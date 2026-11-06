class LocalAuthority < ApplicationRecord
  ACTED_AS_APPROPRIATE_BODY_DATES = {
    introduced_on: Date.new(1999, 9, 1),
    retired_on: Date.new(2024, 8, 1),
  }.freeze

  has_one :appropriate_body_period

  validates :name, presence: true, uniqueness: true
end
