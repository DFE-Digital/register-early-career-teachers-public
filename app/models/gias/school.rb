class GIAS::School < ApplicationRecord
  self.table_name = "gias_schools"
  self.ignored_columns = %i[search]

  include DeclarativeUpdates

  touch -> { contract_period_metadata }, when_changing: %i[name], timestamp_attribute: :api_updated_at

  # Enums
  enum :status,
       { open: "open",
         closed: "closed",
         proposed_to_close: "proposed_to_close",
         proposed_to_open: "proposed_to_open" },
       suffix: true,
       validate: true

  # Associations
  has_one :school, foreign_key: :urn, primary_key: :urn, inverse_of: :gias_school
  has_many :school_funding_eligibilities, foreign_key: :gias_school_urn, primary_key: :urn, inverse_of: :gias_school
  has_many :contract_period_metadata, class_name: "Metadata::SchoolContractPeriod", through: :school
  has_many :gias_school_links, class_name: "GIAS::SchoolLink", foreign_key: :urn, dependent: :destroy, inverse_of: :from_gias_school

  has_many :successor_links,   -> { where(link_type: GIAS::SchoolLink::SUCCESSOR_LINK_TYPES) },   class_name: "GIAS::SchoolLink", foreign_key: :urn, primary_key: :urn
  has_many :predecessor_links, -> { where(link_type: GIAS::SchoolLink::PREDECESSOR_LINK_TYPES) }, class_name: "GIAS::SchoolLink", foreign_key: :urn, primary_key: :urn
  has_many :merger_link, -> { where(link_type: GIAS::SchoolLink::MERGE_LINK_TYPES) }, class_name: "GIAS::SchoolLink", foreign_key: :urn, primary_key: :urn

  has_many :successors, class_name: "GIAS::School", through: :successor_links, source: :to_gias_school
  has_many :predecessors, class_name: "GIAS::School", through: :predecessor_links, source: :from_gias_school

  # Validations
  validates :establishment_number,
            numericality: { only_integer: true, allow_nil: true }

  validates :local_authority_code,
            numericality: { only_integer: true }

  validates :name,
            presence: true

  validates :type_name,
            inclusion: {
              in: GIAS::Types::ALL_TYPES,
              message: "is not a valid school type",
            }

  validates :ukprn,
            numericality: {
              only_integer: true,
              allow_nil: true,
            },
            uniqueness: {
              allow_nil: true,
            }

  validates :urn,
            numericality: {
              only_integer: true,
            },
            uniqueness: true

  # Scopes
  scope :search, ->(q) { where("gias_schools.search @@ websearch_to_tsquery('unaccented', ?)", q) }
  scope :ordered_by_name, -> { order(name: :asc) }

  # Instance Methods
  def closed?
    !open?
  end

  def open?
    open_status? || proposed_to_close_status?
  end

  def successor
    return unless successors.one?

    successors.first
  end

  def can_be_closed?
    closed_status? &&
      closed_on_or_before_today? &&
      !school_closure_recorded? &&
      successors.empty?
  end

  def can_be_opened?
    open_status? &&
      opened_on_or_before_today? &&
      school_not_yet_opened? &&
      predecessors.empty? &&
      successors.empty?
  end

  def can_be_replaced?
    closed_status? &&
      closed_on_or_before_today? &&
      has_one_open_successor? &&
      successor.school_not_yet_opened? &&
      school_replaced?
  end

  def can_be_merged?
    closed_status? &&
      closed_on_or_before_today? &&
      has_one_open_successor? &&
      successor.school_already_opened? &&
      school_merged? 
  end

  def school_not_yet_opened?
    school.blank?
  end

  def school_already_opened?
    school.present?
  end

  def closed_on_or_before_today?
    return false if closed_on.blank?

    closed_on <= Date.current
  end

  def opened_on_or_before_today?
    return false if opened_on.blank?

    opened_on <= Date.current
  end

private

  def school_closure_recorded?
    Event.where(school:, event_type: :school_closed).exists?
  end

  def has_one_open_successor?
    successors.one? &&
      successor.open_status? &&
      successor.opened_on_or_before_today?
  end

  def school_replaced?
    successor_links.where(link_type: GIAS::SchoolLink::SUCESSOR).exists?
  end

  def school_merged?
    successor_links.where(link_type: GIAS::SchoolLink::SUCCESSOR_MERGED).exists?
  end
end
