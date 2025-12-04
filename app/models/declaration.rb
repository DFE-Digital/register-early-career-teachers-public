class Declaration < ApplicationRecord
  belongs_to :training_period
  belongs_to :voided_by_user, class_name: "User", optional: true
  belongs_to :mentorship_period, optional: true
  belongs_to :payment_statement, optional: true, class_name: "Statement"
  belongs_to :clawback_statement, optional: true, class_name: "Statement"

  enum :payment_status,
       %w[not_started eligible payable paid voided ineligible].index_by(&:itself),
       validate: { message: "Choose a valid payment status" },
       prefix: true

  enum :clawback_status,
       %w[not_started awaiting_clawback clawed_back].index_by(&:itself),
       validate: { message: "Choose a valid clawback status" },
       prefix: true

  enum :declaration_type,
       %w[started retained-1 retained-2 retained-3 retained-4 extended-1 extended-2 extended-3 completed].index_by(&:itself),
       validate: { message: "Choose a valid declaration type" }

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
  validates :payment_statement, presence: { message: "Payment statement must be associated for declarations with a payment status" }, unless: :payment_status_not_started?
  validates :clawback_statement, presence: { message: "Clawback statement must be associated for declarations with a clawback status" }, unless: :clawback_status_not_started?
  validate :declaration_date_within_milestone
  validate :mentorship_period_belongs_to_teacher

  state_machine :payment_status, initial: :not_started do
    before_transition from: :ineligible, do: :clear_ineligibility_reason

    event :mark_as_eligible do
      transition %i[not_started] => :eligible
    end

    event :mark_as_payable do
      transition %i[eligible] => :payable
    end

    event :mark_as_paid do
      transition %i[payable] => :paid
    end

    event :mark_as_ineligible do
      transition %i[not_started] => :ineligible
    end

    event :mark_as_voided do
      transition %i[not_started eligible payable ineligible] => :voided
    end
  end

  state_machine :clawback_status, initial: :not_started do
    event :mark_as_awaiting_clawback do
      transition %i[not_started] => :awaiting_clawback, if: :payment_status_paid?
    end

    event :mark_as_clawed_back do
      transition %i[awaiting_clawback] => :clawed_back
    end
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
end
