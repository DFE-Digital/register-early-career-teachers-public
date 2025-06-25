class Statement < ApplicationRecord
  VALID_FEE_TYPES = %w[output service].freeze

  belongs_to :active_lead_provider
  has_many :adjustments
  has_one :lead_provider, through: :active_lead_provider
  has_one :registration_period, through: :active_lead_provider

  def self.maximum_year = Date.current.year + 5

  validates :fee_type,
            presence: { message: 'Enter a fee type' },
            inclusion: { in: VALID_FEE_TYPES, message: "Fee type must be output or service" }
  validates :month, numericality: { in: 1..12, only_integer: true, message: "Month must be a number between 1 and 12" }
  validates :year, numericality: { greater_than_or_equal_to: 2020, is_less_than_or_equal_to: :maximum_year, only_integer: true, message: "Year must be on or after 2020 and on or before #{maximum_year}" }
  validates :active_lead_provider_id, uniqueness: { scope: %i[year month], message: "Statement with the same month and year already exists for the lead provider" }
  validates :api_id, uniqueness: { case_sensitive: false, message: "API id already exists for another statement" }

  scope :with_fee_type, ->(fee_type) { where(fee_type:) }
  scope :with_status, ->(*status) { where(status:) }
  scope :with_statement_date, ->(year:, month:) { where(year:, month:) }

  enum :fee_type, { service: "service", output: "output" }, suffix: 'fee'

  state_machine :status, initial: :open do
    state :open
    state :payable
    state :paid

    event :mark_as_payable do
      transition [:open] => :payable
    end

    event :mark_as_paid do
      transition [:payable] => :paid
    end
  end

  def shorthand_status
    case status
    when "open"
      "OP"
    when "payable"
      "PB"
    when "paid"
      "PD"
    else
      raise ArgumentError, "Unknown status: #{status}"
    end
  end

  def adjustment_editable?
    output_fee? && !paid?
  end

  def can_authorise_payment?
    # TODO: will also need to include: `participant_declarations.any?`
    output_fee && payable? && !marked_as_paid_at? && deadline_date < Date.current
  end
end
