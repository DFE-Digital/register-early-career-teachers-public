class Declaration < ApplicationRecord
  belongs_to :training_period
  belongs_to :voided_by_user, class_name: "User", optional: true
  belongs_to :mentor_teacher, class_name: "Teacher", optional: true
  has_many :statement_line_items, class_name: "Statement::LineItem"

  enum :status, {
    submitted: "submitted",
    eligible: "eligible",
    payable: "payable",
    paid: "paid",
    voided: "voided",
    ineligible: "ineligible",
    awaiting_clawback: "awaiting_clawback",
    clawed_back: "clawed_back"
  }, validate: { message: "Choose a valid status" }, suffix: true

  enum :declaration_type, {
    started: "started",
    "retained-1": "retained-1",
    "retained-2": "retained-2",
    "retained-3": "retained-3",
    "retained-4": "retained-4",
    "extended-1": "extended-1",
    "extended-2": "extended-2",
    "extended-3": "extended-3",
    completed: "completed"
  }, validate: { message: "Choose a valid declaration type" }

  enum :evidence_type, {
    "training-event-attended": "training-event-attended",
    "self-study-material-completed": "self-study-material-completed",
    "materials-engaged-with-offline": "materials-engaged-with-offline",
    "75-percent-engagement-met": "75-percent-engagement-met",
    "75-percent-engagement-met-reduced-induction": "75-percent-engagement-met-reduced-induction",
    "one-term-induction": "one-term-induction",
    other: "other"
  }, validate: { message: "Choose a valid evidence type", allow_nil: true }

  enum :ineligibility_reason, {
    duplicate: "duplicate"
  }, validate: { message: "Choose a valid ineligibility reason", allow_nil: true }

  delegate :for_ect?, :for_mentor?, to: :training_period, allow_nil: true

  validates :training_period, presence: { message: "Choose a training period" }
  validates :voided_by_user, presence: { message: "Voided by user must be set as well as the voided date" }, if: :voided_at
  validates :voided_at, presence: { message: "Voided at must be set as well as the voided by user" }, if: :voided_by_user
  validates :api_id, uniqueness: { case_sensitive: false, message: "API id already exists for another declaration" }
  validates :date, presence: { message: "Date must be specified" }
  validates :declaration_type, inclusion: { in: Declaration.declaration_types.keys, message: "Choose a valid declaration type" }
  validates :evidence_type, inclusion: { in: Declaration.evidence_types.keys, message: "Choose a valid evidence type" }, allow_nil: true
  validates :ineligibility_reason, inclusion: { in: Declaration.ineligibility_reasons.keys, message: "Choose a valid ineligibility reason" }, allow_nil: true
  validates :ineligibility_reason, presence: { message: "Ineligibility reason must be set when the declaration is ineligible" }, if: :ineligible?
  validates :ineligibility_reason, absence: { message: "Ineligibility reason must not be set unless the declaration is ineligible" }, unless: :ineligible?
  validates :mentor_teacher, absence: { message: "Mentor teacher can only be assigned to declarations for ECTs" }, if: :for_mentor?
  validate :at_most_two_statement_line_items
  validate :single_billable_statement_line_item
  validate :single_refundable_statement_line_item
  validate :date_within_milestone
  validate :mentorship_period_exists_for_mentor_teacher

  state_machine :status, initial: :submitted do
    before_transition from: :ineligible, do: :clear_ineligibility_reason

    event :mark_as_eligible do
      transition %i[submitted] => :eligible
    end

    event :mark_as_payable do
      transition %i[eligible] => :payable
    end

    event :mark_as_paid do
      transition %i[payable] => :paid
    end

    event :mark_as_ineligible do
      transition %i[submitted] => :ineligible
    end

    event :mark_as_awaiting_clawback do
      transition %i[paid] => :awaiting_clawback
    end

    event :mark_as_clawed_back do
      transition %i[awaiting_clawback] => :clawed_back
    end

    event :mark_as_voided do
      transition %i[submitted eligible payable ineligible] => :voided
    end
  end

private

  def clear_ineligibility_reason
    self.ineligibility_reason = nil
  end

  def at_most_two_statement_line_items
    return unless statement_line_items.size > 2

    errors.add(:base, "A declaration can have at most two statement line items")
  end

  def single_billable_statement_line_item
    return unless statement_line_items.count(&:billable?) > 1

    errors.add(:base, "A declaration can have only a single billable statement line item")
  end

  def single_refundable_statement_line_item
    return unless statement_line_items.count(&:refundable?) > 1

    errors.add(:base, "A declaration can have only a single refundable statement line item")
  end

  def date_within_milestone
    return unless milestone && date

    if date < milestone.start_date.beginning_of_day
      errors.add(:date, "Date must be on or after the milestone start date for the same declaration type")
    end

    if milestone.milestone_date && milestone.milestone_date.end_of_day <= date
      errors.add(:date, "Date must be on or before the milestone date for the same declaration type")
    end
  end

  def milestone
    training_period&.schedule&.milestones&.find_by(declaration_type:)
  end

  def mentorship_period_exists_for_mentor_teacher
    return unless mentor_teacher && training_period

    unless training_period.trainee.mentorship_periods.exists? { it.mentor.teacher_id == mentor_teacher.id }
      errors.add(:mentor_teacher, "Mentor teacher must have a mentorship period in the declaration's training period")
    end
  end
end
