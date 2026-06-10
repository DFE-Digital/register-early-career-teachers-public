class GIAS::SchoolLink < ApplicationRecord
  self.table_name = "gias_school_links"

  OTHER_LINK_TYPES = [
    "Children's Centre Link",
    "Closure",
    "Expansion",
    "Other",
    "Result of Amalgamation",
    "Sixth Form Centre Link",
    "Sixth Form Centre School",
  ].freeze

  MERGE_LINK_TYPES = [
    "Merged - change in age range",
    "Merged - expansion in school capacity and changer in age range",
    "Merged - expansion of school capacity"
  ].freeze

  PREDECESSOR_LINK_TYPES = [
    "Predecessor - amalgamated",
    "Predecessor - merged",
    "Predecessor - Split School",
    "Predecessor"
  ].freeze

  SUCCESSOR_MERGED = "Successor - merged"
  SUCCESSOR_SPLIT  = "Successor - Split School"
  SUCCESSOR_AMALGAMATED = "Successor - amalgamated"
  SUCESSOR = "Successor"

  SUCCESSOR_LINK_TYPES = [
    SUCCESSOR_AMALGAMATED,
    SUCCESSOR_MERGED,
    SUCCESSOR_SPLIT,
    SUCESSOR
  ].freeze

  LINK_TYPES = (OTHER_LINK_TYPES + MERGE_LINK_TYPES + SUCCESSOR_LINK_TYPES + PREDECESSOR_LINK_TYPES).uniq.sort.freeze

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
