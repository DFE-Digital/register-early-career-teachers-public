module Interval
  extend ActiveSupport::Concern

  included do
    # Validations
    validate :period_dates_validation

    # Scopes
    scope :overlapping_with, ->(period) { where("range && daterange(?, ?)", period.started_on, period.finished_on) }
    scope :ongoing, -> { where(finished_on: nil) }
    scope :finished, -> { where.not(finished_on: nil) }
    scope :earliest_first, -> { order(started_on: 'asc') }
    scope :latest_first, -> { order(started_on: 'desc') }
    scope :started_before, ->(date) { where(started_on: ...date) }
    scope :started_on_or_after, ->(date) { where(started_on: date..) }
    scope :finished_before, ->(date) { where(finished_on: ...date) }
    scope :finished_on_or_after, ->(date) { where(finished_on: date..) }
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

  def overlaps_with_siblings? = siblings.overlapping_with(self).exists?

  def predecessors = siblings.started_before(started_on)

  def predecessors? = predecessors.exists?

  def siblings =  raise(NotImplementedError)

  def siblings? = siblings.exists?

  def successors = finished_on ? siblings.started_on_or_after(finished_on) : self.class.none

  def successors? = successors.exists?
end
