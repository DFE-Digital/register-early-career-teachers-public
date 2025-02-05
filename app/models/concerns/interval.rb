module Interval
  extend ActiveSupport::Concern

  included do
    # Validations
    validate :period_dates_validation

    # Scopes
    scope :overlapping_with, ->(period) { where("range && daterange(?, ?)", period.started_on, period.finished_on) }

    scope :ongoing, -> { where(finished_on: nil) }

    scope :containing_period, ->(period) { where("range @> daterange(?, ?)", period.started_on, period.finished_on) }
  end

  def ongoing?
    finished_on.nil?
  end

  def finish!(finished_on = Date.current)
    update!(finished_on:)
  end

  def period_dates_validation
    return if [started_on, finished_on].any?(&:blank?)

    errors.add(:finished_on, "The finish date must be later than the start date (#{started_on.to_fs(:govuk)})") if finished_on <= started_on
  end
end
