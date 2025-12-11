class Declaration < ApplicationRecord
  BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES = %w[no_payment eligible payable paid].freeze

  belongs_to :training_period
  belongs_to :voided_by_user, class_name: "User", optional: true
  belongs_to :mentorship_period, optional: true
  belongs_to :payment_statement, optional: true, class_name: "Statement"
  belongs_to :clawback_statement, optional: true, class_name: "Statement"

  enum :payment_status,
       %w[no_payment eligible payable paid voided ineligible].index_by(&:itself),
       validate: { message: "Choose a valid payment status" },
       prefix: true

  enum :clawback_status,
       %w[no_clawback awaiting_clawback clawed_back].index_by(&:itself),
       validate: { message: "Choose a valid clawback status" },
       prefix: true

  enum :declaration_type,
       %w[started retained-1 retained-2 retained-3 retained-4 extended-1 extended-2 extended-3 completed].index_by(&:itself),
       validate: { message: "Choose a valid declaration type" },
       prefix: true

  enum :evidence_type,
       %w[
         training-event-attended
         self-study-material-completed
         materials-engaged-with-offline
         75-percent-engagement-met
         75-percent-engagement-met-reduced-induction
         one-term-induction
         other
       ].index_by(&:itself),
       validate: { message: "Choose a valid evidence type", allow_nil: true }

  enum :ineligibility_reason,
       %w[duplicate].index_by(&:itself),
       validate: { message: "Choose a valid ineligibility reason", allow_nil: true }

  delegate :for_ect?, :for_mentor?, to: :training_period, allow_nil: true

  validates :training_period, presence: { message: "Choose a training period" }
  validates :voided_by_user, presence: { message: "Voided by user must be set as well as the voided date" }, if: :voided_at
  validates :voided_at, presence: { message: "Voided at must be set as well as the voided by user" }, if: :voided_by_user
  validates :api_id, uniqueness: { case_sensitive: false, message: "API id already exists for another declaration" }
  validates :declaration_date, presence: { message: "Declaration date must be specified" }
  validates :declaration_type, inclusion: { in: Declaration.declaration_types.keys, message: "Choose a valid declaration type" }
  validates :evidence_type, inclusion: { in: Declaration.evidence_types.keys, message: "Choose a valid evidence type" }, allow_nil: true
  validates :ineligibility_reason, inclusion: { in: Declaration.ineligibility_reasons.keys, message: "Choose a valid ineligibility reason" }, allow_nil: true
  validates :ineligibility_reason, presence: { message: "Ineligibility reason must be set when the declaration is ineligible" }, if: :ineligible?
  validates :ineligibility_reason, absence: { message: "Ineligibility reason must not be set unless the declaration is ineligible" }, unless: :ineligible?
  validates :mentorship_period, absence: { message: "Mentor teacher can only be assigned to declarations for ECTs" }, if: :for_mentor?
  validates :payment_statement, presence: { message: "Payment statement must be associated for declarations with a payment status" }, unless: :payment_status_no_payment?
  validates :clawback_statement, presence: { message: "Clawback statement must be associated for declarations with a clawback status" }, unless: :clawback_status_no_clawback?
  validate :declaration_date_within_milestone
  validate :mentorship_period_belongs_to_teacher
  validate :contract_period_consistent_across_associations

  state_machine :payment_status, initial: :no_payment do
    state :no_payment, :ineligible, :eligible, :payable, :paid, :voided

    before_transition from: :ineligible, do: :clear_ineligibility_reason

    event :mark_as_eligible do
      transition %i[no_payment] => :eligible
    end

    event :mark_as_payable do
      transition %i[eligible] => :payable
    end

    event :mark_as_paid do
      transition %i[payable] => :paid
    end

    event :mark_as_ineligible do
      transition %i[no_payment] => :ineligible
    end

    event :mark_as_voided do
      transition %i[no_payment eligible payable ineligible] => :voided
    end
  end

  state_machine :clawback_status, initial: :no_clawback do
    state :no_clawback, :awaiting_clawback, :clawed_back

    event :mark_as_awaiting_clawback do
      transition %i[no_clawback] => :awaiting_clawback, if: :payment_status_paid?
    end

    event :mark_as_clawed_back do
      transition %i[awaiting_clawback] => :clawed_back
    end
  end

  def billable_or_changeable?
    payment_status.in?(BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES) &&
      clawback_status_no_clawback?
  end

private

  def clear_ineligibility_reason
    self.ineligibility_reason = nil
  end

  def declaration_date_within_milestone
    return unless milestone && declaration_date

    if declaration_date < milestone.start_date.beginning_of_day
      errors.add(:declaration_date, "Declaration date must be on or after the milestone start date for the same declaration type")
    end

    if milestone.milestone_date && milestone.milestone_date.end_of_day <= declaration_date
      errors.add(:declaration_date, "Declaration date must be on or before the milestone date for the same declaration type")
    end
  end

  def milestone
    training_period&.schedule&.milestones&.find_by(declaration_type:)
  end

  def mentorship_period_belongs_to_teacher
    return unless mentorship_period && training_period

    unless mentorship_period.in?(training_period.trainee.mentorship_periods)
      errors.add(:mentorship_period, "Mentorship period must belong to the trainee")
    end
  end

  def contract_period_consistent_across_associations
    associated_contract_periods = [training_period&.contract_period, payment_statement&.contract_period, clawback_statement&.contract_period]

    return unless associated_contract_periods.compact.uniq.many?

    errors.add(:training_period, "Contract period mismatch: training period, payment_statement and clawback_statement must have the same contract period.")
  end
end
