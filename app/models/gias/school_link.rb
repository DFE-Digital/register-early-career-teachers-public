class GIAS::SchoolLink < ApplicationRecord
  self.table_name = "gias_school_links"

  LINK_TYPES = [
    "Closure",
    "Expansion",
    "Merged - change in age range",
    "Merged - expansion in school capacity and changer in age range",
    "Merged - expansion of school capacity",
    "Other",
    "Predecessor - amalgamated",
    "Predecessor - merged",
    "Predecessor - Split School",
    "Predecessor",
    "Result of Amalgamation",
    "Sixth Form Centre Link",
    "Sixth Form Centre School",
    "Successor - amalgamated",
    "Successor - merged",
    "Successor - Split School",
    "Successor"
  ].freeze

  # Associations
  belongs_to :from_gias_school, class_name: "GIAS::School", foreign_key: :urn, primary_key: :urn, inverse_of: :gias_school_links
  belongs_to :to_gias_school, class_name: "GIAS::School", foreign_key: :link_urn, primary_key: :urn

  # Validations
  validates :link_type,
            inclusion: { in: LINK_TYPES }

  validates :link_urn,
            presence: true,
            uniqueness: { scope: :urn }

  validates :urn,
            numericality: { only_integer: true }
end
