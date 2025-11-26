class Statement::PaymentItem < ApplicationRecord
  belongs_to :statement
  belongs_to :declaration

  enum :status, {
    eligible: "eligible",
    payable: "payable",
    paid: "paid",
    voided: "voided",
    ineligible: "ineligible",
  }, validate: { message: "Choose a valid status" }, suffix: true

  validates :statement_id, presence: { message: "Statement must be specified" }
  validates :declaration_id, presence: { message: "Declaration must be specified" }
  validates :declaration_id, uniqueness: { message: "Declaration can only have one payment item" }
  validates :ecf_id, uniqueness: { case_sensitive: false, message: "ECF ID must be unique" }, allow_nil: true

  state_machine :status, initial: :eligible do
    state :eligible
    state :payable
    state :paid
    state :voided
    state :ineligible

    event :mark_as_payable do
      transition [:eligible] => :payable
    end

    event :mark_as_paid do
      transition [:payable] => :paid
    end

    event :mark_as_voided do
      transition %i[eligible ineligible payable] => :voided
    end

    event :mark_as_ineligible do
      transition [:eligible] => :ineligible
    end
  end
end
