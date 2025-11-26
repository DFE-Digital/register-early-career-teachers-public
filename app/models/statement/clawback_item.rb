class Statement::ClawbackItem < ApplicationRecord
  belongs_to :statement
  belongs_to :declaration

  enum :status, {
    awaiting_clawback: "awaiting_clawback",
    clawed_back: "clawed_back",
  }, validate: { message: "Choose a valid status" }, suffix: true

  validates :statement_id, presence: { message: "Statement must be specified" }
  validates :declaration_id, presence: { message: "Declaration must be specified" }
  validates :declaration_id, uniqueness: { message: "Declaration can only have one clawback item" }
  validates :ecf_id, uniqueness: { case_sensitive: false, message: "ECF ID must be unique" }, allow_nil: true
  validate :declaration_has_billable_payment_item

  state_machine :status, initial: :awaiting_clawback do
    state :awaiting_clawback
    state :clawed_back

    event :mark_as_clawed_back do
      transition [:awaiting_clawback] => :clawed_back
    end
  end

private

  def declaration_has_billable_payment_item
    return unless declaration
    return if declaration.statement_payment_item&.paid?

    errors.add(:declaration_id, "Declaration must have a paid payment item before creating a clawback item")
  end
end
