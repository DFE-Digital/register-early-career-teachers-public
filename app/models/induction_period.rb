class InductionPeriod < ApplicationRecord
  include Interval
  include SharedInductionPeriodValidation

  # Associations
  belongs_to :appropriate_body
  belongs_to :teacher
  has_many :events

  # Validations
  validates :started_on,
            presence: true

  validates :number_of_terms,
            inclusion: {
              in: 0..16, message: "Terms must be between 0 and 16", if: -> { finished_on.present? }
            },
            presence: {
              message: "Enter a number of terms", if: -> { finished_on.present? }
            },
            absence: {
              message: "Delete the number of terms if the induction has no end date", if: -> { finished_on.blank? }
            }

  validates :induction_programme,
            inclusion: { in: %w[fip cip diy],
                         message: "Choose an induction programme" }

  validate :start_date_after_qts_date
  validate :teacher_distinct_period, if: -> { valid_date_order? }

  scope :for_teacher, ->(teacher) { where(teacher:) }
  scope :for_appropriate_body, ->(appropriate_body) { where(appropriate_body:) }
  scope :siblings_of, ->(instance) { for_teacher(instance.teacher).excluding(instance) }

private

  def valid_date_order?
    return true if started_on.blank? || finished_on.blank?

    started_on <= finished_on
  end

  def teacher_distinct_period
    overlapping_siblings = InductionPeriod.siblings_of(self).overlapping_with(self).exists?

    errors.add(:base, "Induction periods cannot overlap") if overlapping_siblings
  end

  def start_date_after_qts_date
    return if teacher.blank?

    ensure_start_date_after_qts_date(teacher.trs_qts_awarded_on)
  end
end
