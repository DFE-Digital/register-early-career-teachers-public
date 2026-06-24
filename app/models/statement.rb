class Statement < ApplicationRecord
  include DeclarativeUpdates

  VALID_FEE_TYPES = %w[output service].freeze

  # Associations
  belongs_to :contract
  has_many :adjustments, dependent: :destroy
  has_many :payment_declarations, inverse_of: :payment_statement, class_name: "Declaration"
  has_many :clawback_declarations, inverse_of: :clawback_statement, class_name: "Declaration"
  has_one :active_lead_provider, through: :contract
  has_one :lead_provider, through: :active_lead_provider
  has_one :contract_period, through: :active_lead_provider

  # Enums
  enum :status,
       %w[open payable paid].index_by(&:itself),
       validate: { message: "Choose a valid status" },
       prefix: true
  enum :fee_type,
       %w[output service].index_by(&:itself),
       validate: { message: "Fee type must be output or service" },
       suffix: "fee"

  def self.maximum_year = Date.current.year + 5

  # Validations
  validates :contract, presence: { message: "Contract is required" }
  validates :fee_type, presence: { message: "Enter a fee type" }
  validates :status, presence: { message: "Enter a status" }
  validates :month, numericality: { in: 1..12, only_integer: true, message: "Month must be a number between 1 and 12" }
  validates :year, numericality: { greater_than_or_equal_to: 2020, is_less_than_or_equal_to: :maximum_year, only_integer: true, message: "Year must be on or after 2020 and on or before #{maximum_year}" }
  validates :api_id, uniqueness: { case_sensitive: false, message: "API id already exists for another statement" }
  validate :unique_lead_provider_month_year
  validates :deadline_date, presence: { message: "Deadline date must be specified" }
  validate :deadline_date_in_the_past
  validates :payment_date,
            comparison: {
              greater_than: :deadline_date,
              message: "Payment date must be later than the deadline date"
            }

  # Scopes
  scope :with_fee_type, ->(fee_type) { where(fee_type:) }
  scope :with_status, ->(*status) { where(status:) }
  scope :with_statement_date, ->(year:, month:) { where(year:, month:) }

  touch -> { self }, timestamp_attribute: :api_updated_at

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

  def month_year
    "#{Date::MONTHNAMES[month]} #{year}"
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
    output_fee? &&
      payable? &&
      !marked_as_paid_at? &&
      has_outstanding_declarations? &&
      deadline_date.before?(Date.current)
  end

  def referenced_by_declarations?
    payment_declarations.exists? || clawback_declarations.exists?
  end

private

  def unique_lead_provider_month_year
    return unless active_lead_provider

    existing = Statement.joins(:contract)
                        .where(contracts: { active_lead_provider_id: active_lead_provider.id })
                        .where(month:, year:)
                        .where.not(id:)
                        .exists?

    return unless existing

    errors.add(:base, "Statement with the same month and year already exists for this active lead provider")
  end

  def deadline_date_in_the_past
    return unless payable? || paid?
    return if deadline_date.before?(Date.current)

    errors.add(:deadline_date, "Deadline date must be in the past")
  end

  def has_outstanding_declarations?
    payment_declarations.payment_status_payable.exists? || clawback_declarations.clawback_status_awaiting_clawback.exists?
  end
end
