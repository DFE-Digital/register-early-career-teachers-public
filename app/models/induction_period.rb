class InductionPeriod < ApplicationRecord
  VALID_NUMBER_OF_TERMS = { min: 0, max: 16 }.freeze
  include Interval
  include SharedInductionPeriodValidation
  include SharedNumberOfTermsValidation

  # Associations
  belongs_to :appropriate_body
  belongs_to :teacher
  has_many :events

  # Validations
  validates :started_on,
            presence: true

  validates :induction_programme,
            inclusion: { in: %w[fip cip diy unknown pre_september_2021],
                         message: "Choose an induction programme" }

  validate :start_date_after_qts_date
  validate :teacher_distinct_period, if: -> { valid_date_order? }
  validate :end_date_admin_only, if: -> { started_on.present? }

  scope :for_teacher, ->(teacher) { where(teacher:) }
  scope :for_appropriate_body, ->(appropriate_body) { where(appropriate_body:) }

  # Instance methods
  def siblings
    return InductionPeriod.none unless teacher

    teacher.induction_periods.excluding(self)
  end

private

  # Ensure admin users inserting new induction periods include end dates.
  def end_date_admin_only
    return unless inserting_induction_period? && finished_on.blank?

    errors.add(:finished_on, "End date is required for inserted periods")
  end

  def inserting_induction_period?
    siblings.any? do |sibling|
      started_on.before?(sibling.started_on) || (started_on.after?(sibling.finished_on) && !sibling.eql?(last_finished_sibling))
    end
  end

  def start_date_after_qts_date
    return if teacher.blank?

    ensure_start_date_after_qts_date(teacher.trs_qts_awarded_on)
  end

  def teacher_distinct_period
    overlap_validation(name: 'induction')
  end
end
