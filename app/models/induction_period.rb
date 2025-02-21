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

  scope :for_teacher, ->(teacher) { where(teacher:) }
  scope :for_appropriate_body, ->(appropriate_body) { where(appropriate_body:) }
  scope :siblings_of, ->(instance) { for_teacher(instance.teacher).excluding(instance) }

private

  def valid_date_order?
    return true if started_on.blank? || finished_on.blank?

    started_on <= finished_on
  end

  def teacher_distinct_period
    return unless overlaps_with_siblings?

    if siblings.any? { |s| s.range.include?(started_on) }
      errors.add(:started_on, "Start date cannot overlap another induction period")
    elsif siblings.any? { |s| s.range.include?(finished_on) }
      errors.add(:finished_on, "End date cannot overlap another induction period")
    end
  end

  def siblings
    InductionPeriod.siblings_of(self)
  end

  def overlaps_with_siblings?
    siblings.overlapping_with(self).exists?
  end

  def start_date_after_qts_date
    return if teacher.blank?

    ensure_start_date_after_qts_date(teacher.trs_qts_awarded_on)
  end
end
