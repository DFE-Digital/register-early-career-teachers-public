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
    scope :ongoing_on, ->(date) { where("range @> ?::date", date) }
  end

  # Validations
  def period_dates_validation
    return if incomplete?

    errors.add(:finished_on, "The end date must be later than the start date (#{started_on.to_fs(:govuk)})") if invalid_date_order?
  end

  def overlap_validation(name:)
    return unless has_overlap_with_siblings?

    if siblings.any? { |s| s.range.include?(started_on) }
      errors.add(:started_on, "Start date cannot overlap another #{name} period")
    elsif siblings.any? { |s| s.range.include?(finished_on) }
      errors.add(:finished_on, "End date cannot overlap another #{name} period")
    end
  end

  # Actions
  def finish!(finished_on = Date.current)
    update!(finished_on:)
  end

  # Associations
  def predecessors = siblings.started_before(started_on)

  def siblings = raise(NotImplementedError)

  def successors = finished_on ? siblings.started_on_or_after(finished_on) : self.class.none

  # Predicates
  def valid_date_order?
    return true if incomplete?

    started_on <= finished_on
  end

  def invalid_date_order?
    finished_on <= started_on
  end

  def ongoing? = finished_on.nil?

  def complete? = finished_on.present?

  def incomplete? = [started_on, finished_on].any?(&:blank?)

  def has_overlap_with_siblings? = siblings.overlapping_with(self).exists?

  def has_predecessors? = predecessors.exists?

  def has_siblings? = siblings.exists?

  def has_successors? = successors.exists?

  # Methods
  def last_finished_sibling
    siblings.finished.earliest_first.last
  end
end
