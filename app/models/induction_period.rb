class InductionPeriod < ApplicationRecord
  include Interval
  include CommonInductionPeriodValidation

  # Associations
  belongs_to :appropriate_body
  belongs_to :teacher
  has_many :events

  # Validations
  validates :started_on,
            presence: true

  validates :appropriate_body_id,
            presence: true

  validates :number_of_terms,
            presence: { message: "Enter a number of terms",
                        if: -> { finished_on.present? } }

  validates :induction_programme,
            inclusion: { in: %w[fip cip diy],
                         message: "Choose an induction programme" }

  validate :started_on_not_in_future, if: -> { started_on.present? }
  validate :finished_on_not_in_future, if: -> { finished_on.present? }
  validate :start_date_after_qts_date
  validate :teacher_distinct_period, if: -> { valid_date_order? }

  # Scopes
  scope :for_teacher, ->(teacher) { where(teacher:) }
  scope :for_appropriate_body, ->(appropriate_body) { where(appropriate_body:) }
  scope :siblings_of, ->(instance) { for_teacher(instance.teacher).excluding(instance) }

private

  def started_on_not_in_future
    return if started_on <= Date.current

    errors.add(:started_on, "Start date cannot be in the future")
  end

  def finished_on_not_in_future
    return if finished_on <= Date.current

    errors.add(:finished_on, "End date cannot be in the future")
  end

  def start_date_after_qts_date
    return if started_on.blank? || teacher.trs_qts_awarded_on.blank?
    return if started_on >= teacher.trs_qts_awarded_on

    errors.add(:started_on, "Start date cannot be before QTS award date (#{teacher.trs_qts_awarded_on.to_fs(:govuk)})")
  end

  def valid_date_order?
    return true if started_on.blank? || finished_on.blank?

    started_on <= finished_on
  end

  def teacher_distinct_period
    overlapping_siblings = InductionPeriod.siblings_of(self).overlapping_with(self).exists?

    errors.add(:base, "Induction periods cannot overlap") if overlapping_siblings
  end
end
