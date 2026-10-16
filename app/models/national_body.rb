class NationalBody < ApplicationRecord
  # Independent schools in England and overseas
  ISTIP = "Independent Schools Teacher Induction Panel (ISTIP)"

  # British international schools overseas
  ESP = "Educational Success Partners (ESP)"

  has_many :appropriate_body_periods

  validates :name, presence: true, uniqueness: true
end
