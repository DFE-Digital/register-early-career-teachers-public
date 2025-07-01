module SharedInductionPeriodValidation
  extend ActiveSupport::Concern

  included do
    validate :started_on_from_september_2021_onwards, if: -> { started_on.present? }, on: :register_ect

    validate :started_on_from_september_1999_onwards, if: -> { started_on.present? }

    validates :appropriate_body_id, presence: { message: "Select an appropriate body" }, unless: :admin_import?

    validate :started_on_not_in_future, if: -> { started_on.present? }

    validate :finished_on_not_in_future, if: -> { finished_on.present? }
  end

  def started_on_from_september_1999_onwards
    return if started_on >= ::STATUTORY_INDUCTION_ROLLOUT_DATE

    errors.add(:started_on, "Enter a start date after 1 September 1999")
  end

  def started_on_from_september_2021_onwards
    return if started_on >= ::ECF_ROLLOUT_DATE

    errors.add(:started_on, "Enter a start date after 1 September 2021")
  end

  def started_on_not_in_future
    return if started_on <= Date.current

    errors.add(:started_on, "Start date cannot be in the future")
  end

  def finished_on_not_in_future
    return if finished_on <= Date.current

    errors.add(:finished_on, "End date cannot be in the future")
  end

  def ensure_start_date_after_qts_date(qts_award_date)
    return if started_on.blank? || qts_award_date.blank?
    return if started_on >= qts_award_date

    errors.add(:started_on, "Start date cannot be before QTS award date (#{qts_award_date.to_fs(:govuk)})")
  end
end
