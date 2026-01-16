class Declaration < ApplicationRecord
  include DeclarativeUpdates

  BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES = %w[no_payment eligible payable paid].freeze
  VOIDABLE_PAYMENT_STATUSES = %w[no_payment eligible payable ineligible].freeze

  # Associations
  belongs_to :training_period
  belongs_to :voided_by_user, class_name: "User", optional: true
  belongs_to :mentorship_period, optional: true
  belongs_to :payment_statement, optional: true, class_name: "Statement"
  belongs_to :clawback_statement, optional: true, class_name: "Statement"
  has_one :lead_provider, through: :training_period
  has_one :delivery_partner, through: :training_period
  has_one :contract_period, through: :training_period
  has_one :ect_at_school_period, through: :training_period
  has_one :ect_teacher, through: :ect_at_school_period, source: :teacher
  has_one :mentor_at_school_period, through: :training_period
  has_one :mentor_teacher, through: :mentor_at_school_period, source: :teacher

  # Enums
  enum :payment_status,
       %w[no_payment eligible payable paid voided ineligible].index_by(&:itself),
       validate: { message: "Choose a valid payment status" },
       prefix: true

  enum :clawback_status,
       %w[no_clawback awaiting_clawback clawed_back].index_by(&:itself),
       validate: { message: "Choose a valid clawback status" },
       prefix: true

  # Declaration types are in specific order used for validation to maintain submission order
  enum :declaration_type,
       %w[
         started
         retained-1
         retained-2
         retained-3
         retained-4
         completed
         extended-1
         extended-2
         extended-3
       ].index_by(&:itself),
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

  # Delegations
  delegate :for_ect?, :for_mentor?, to: :training_period, allow_nil: true

  # Validations
  validates :training_period, presence: { message: "Choose a training period" }
  validates :voided_by_user, presence: { message: "Voided by user must be set as well as the voided date" }, if: :voided_by_user_at
  validates :voided_by_user_at, presence: { message: "Voided by user at must be set as well as the voided by user" }, if: :voided_by_user
  validates :api_id, uniqueness: { case_sensitive: false, message: "API id already exists for another declaration" }
  validates :declaration_date, presence: { message: "Declaration date must be specified" }, declaration_date_within_milestone: true
  validates :declaration_type, inclusion: { in: Declaration.declaration_types.keys, message: "Choose a valid declaration type" }
  validates :evidence_type, inclusion: { in: Declaration.evidence_types.keys, message: "Choose a valid evidence type" }, allow_nil: true
  validates :ineligibility_reason, inclusion: { in: Declaration.ineligibility_reasons.keys, message: "Choose a valid ineligibility reason" }, allow_nil: true
  validates :ineligibility_reason, presence: { message: "Ineligibility reason must be set when the declaration is ineligible" }, if: :ineligible?
  validates :ineligibility_reason, absence: { message: "Ineligibility reason must not be set unless the declaration is ineligible" }, unless: :ineligible?
  validates :mentorship_period, absence: { message: "Mentor teacher can only be assigned to declarations for ECTs" }, if: :for_mentor?
  validates :payment_statement, presence: { message: "Payment statement must be associated for declarations with a payment status" }, unless: :payment_status_no_payment?
  validates :clawback_statement, presence: { message: "Clawback statement must be associated for declarations with a clawback status" }, unless: :clawback_status_no_clawback?
  validate :mentorship_period_belongs_to_teacher
  validate :contract_period_consistent_across_associations
  validate :declaration_does_not_already_exist
  validate :declaration_type_started_or_completed_for_mentor_funding_contract_period
  validate :uplifts_absent_for_mentor, if: :for_mentor?

  # Scopes
  scope :billable_or_changeable, -> {
    where(payment_status: BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES, clawback_status: :no_clawback)
  }
  scope :billable_or_changeable_for_declaration_type, ->(declaration_type) {
    billable_or_changeable.where(declaration_type:)
  }

  touch -> { self },
        timestamp_attribute: :api_updated_at,
        when_changing: %i[
          api_id
          mentorship_period_id
          training_period_id
          payment_statement_id
          clawback_statement_id
          declaration_type
          declaration_date
          payment_status
          clawback_status
          ineligibility_reason
          sparsity_uplift
          pupil_premium_uplift
          evidence_type
        ]

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

  def overall_status
    return clawback_status unless clawback_status_no_clawback?

    payment_status
  end

  def uplift_paid?
    training_period.for_ect? &&
      declaration_type_started? &&
      payment_status_paid? &&
      (sparsity_uplift || pupil_premium_uplift)
  end

  def voidable_payment? = payment_status.in?(VOIDABLE_PAYMENT_STATUSES)

  def teacher
    training_period&.teacher
  end

  def duplicate_declaration_exists?
    return unless billable_or_changeable?

    existing_declarations = if training_period.for_ect?
                              teacher.ect_declarations
                            else
                              teacher.mentor_declarations
                            end

    existing_declarations
      .billable_or_changeable
      .where(declaration_type:)
      .excluding(self)
      .exists?
  end

  def milestone
    training_period&.schedule&.milestones&.find_by(declaration_type:)
  end

private

  def clear_ineligibility_reason
    self.ineligibility_reason = nil
  end

  def mentorship_period_belongs_to_teacher
    return unless mentorship_period && training_period

    unless mentorship_period.in?(training_period.mentorship_periods)
      errors.add(:mentorship_period, "Mentorship period must belong to the trainee")
    end
  end

  def contract_period_consistent_across_associations
    associated_contract_periods = [training_period&.contract_period, payment_statement&.contract_period, clawback_statement&.contract_period]

    return unless associated_contract_periods.compact.uniq.many?

    errors.add(:training_period, "Contract period mismatch: training period, payment_statement and clawback_statement must have the same contract period.")
  end

  def declaration_does_not_already_exist
    return unless training_period && declaration_type

    errors.add(:base, "A matching declaration already exists.") if duplicate_declaration_exists?
  end

  def declaration_type_started_or_completed_for_mentor_funding_contract_period
    return unless training_period&.for_mentor?
    return unless training_period&.contract_period&.mentor_funding_enabled?

    unless declaration_type_started? || declaration_type_completed?
      errors.add(:declaration_type, "Only 'started' or 'completed' declaration types are allowed for mentor funding enabled contract periods.")
    end
  end

  def uplifts_absent_for_mentor
    return unless for_mentor?

    if sparsity_uplift.present?
      errors.add(:sparsity_uplift, "must be absent for mentor declarations.")
    end

    if pupil_premium_uplift.present?
      errors.add(:pupil_premium_uplift, "must be absent for mentor declarations.")
    end
  end
end
