class Statement::LineItem < ApplicationRecord
  BILLABLE_STATUS = %w[eligible payable paid].freeze
  REFUNDABLE_STATUS = %w[awaiting_clawback clawed_back].freeze

  belongs_to :statement
  belongs_to :declaration

  enum :status, {
    eligible: "eligible",
    payable: "payable",
    paid: "paid",
    voided: "voided",
    ineligible: "ineligible",
    awaiting_clawback: "awaiting_clawback",
    clawed_back: "clawed_back"
  }, validate: { message: "Choose a valid status" }, suffix: true

  validates :statement_id, presence: { message: "Statement must be specified" }
  validates :declaration_id, presence: { message: "Declaration must be specified" }
  validates :status, uniqueness: { scope: %i[declaration_id], message: "Status must be unique per declaration" }
  validates :ecf_id, uniqueness: { case_sensitive: false, message: "ECF ID must be unique" }, allow_nil: true
  validate :at_most_two_per_declaration
  validate :single_billable_per_declaration
  validate :single_refundable_per_declaration
  validate :refundable_only_if_billable

  scope :refundable_status, -> { where(status: REFUNDABLE_STATUS) }
  scope :billable_status, -> { where(status: BILLABLE_STATUS) }

  def billable_status?
    status.in?(BILLABLE_STATUS)
  end

  def refundable_status?
    status.in?(REFUNDABLE_STATUS)
  end

  state_machine :status, initial: :eligible do
    state :eligible
    state :payable
    state :paid
    state :voided
    state :ineligible
    state :awaiting_clawback
    state :clawed_back

    event :mark_as_payable do
      transition [:eligible] => :payable
    end

    event :mark_as_paid do
      transition [:payable] => :paid
    end

    event :mark_as_voided do
      transition %i[eligible ineligible payable] => :voided
    end

    event :mark_as_clawed_back do
      transition [:awaiting_clawback] => :clawed_back
    end

    event :mark_as_ineligible do
      transition [:eligible] => :ineligible
    end
  end

private

  def at_most_two_per_declaration
    return unless declaration
    return unless declaration.statement_line_items.excluding(self).count >= 2

    errors.add(:declaration_id, "A declaration can have at most two statement line items")
  end

  def single_billable_per_declaration
    return unless declaration
    return unless billable_status? && declaration.statement_line_items.billable_status.excluding(self).exists?

    errors.add(:declaration_id, "A declaration can have at most one billable statement line item")
  end

  def single_refundable_per_declaration
    return unless declaration
    return unless refundable_status? && declaration.statement_line_items.refundable_status.excluding(self).exists?

    errors.add(:declaration_id, "A declaration can have at most one refundable statement line item")
  end

  def uniqueness_per_declaration
    return unless declaration

    errors.add(:declaration_id, "A declaration can have at most one refundable statement line item")
  end

  def refundable_only_if_billable
    return unless declaration
    return unless refundable_status? && !declaration.statement_line_items.billable_status.exists?

    errors.add(:declaration_id, "A refundable statement line item requires an associated billable statement line item")
  end
end
