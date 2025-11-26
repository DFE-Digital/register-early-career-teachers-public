class Statement::LineItem < ApplicationRecord
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
  validates :status, uniqueness: { scope: %i[declaration_id statement_id], message: "Status must be unique per declaration and statement" }
  validates :ecf_id, uniqueness: { case_sensitive: false, message: "ECF ID must be unique" }, allow_nil: true

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

    event :mark_as_awaiting_clawback do
      transition [:paid] => :awaiting_clawback
    end

    event :mark_as_clawed_back do
      transition [:awaiting_clawback] => :clawed_back
    end

    event :mark_as_ineligible do
      transition [:eligible] => :ineligible
    end
  end
end
