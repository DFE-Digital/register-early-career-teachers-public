module Interval
  extend ActiveSupport::Concern

  included do
    include Queries::RangeQueries
    # Validations
    validate :period_dates_validation

    # Scopes
    scope :unarchived, -> { all }
    scope :unfinished, -> { unarchived.where(finished_on: nil) }
    scope :finished, -> { unarchived.where.not(finished_on: nil) }
    scope :earliest_first, -> { unarchived.order(started_on: "asc") }
    scope :latest_first, -> { unarchived.order(started_on: "desc") }
    scope :started_before, ->(date) { unarchived.where(started_on: ...date) }
    scope :started_after, ->(date) { unarchived.where("#{table_name}.started_on > ?", date) }
    scope :started_on_or_before, ->(date) { unarchived.where(started_on: ..date) }
    scope :started_on_or_after, ->(date) { unarchived.where(started_on: date..) }
    scope :finished_before, ->(date) { unarchived.where(finished_on: ...date) }
    scope :finished_on_or_after, ->(date) { unarchived.where(finished_on: date..) }
    scope :overlapping_with, ->(period) { unarchived.where(*overlapping_with_range(period.started_on, period.finished_on)) }
    scope :containing_period, ->(period) { unarchived.where(*containing_range(period.started_on, period.finished_on)) }
    scope :contains_date, ->(date) { unarchived.where(*date_in_range(date)) }
    scope :closest_to, ->(date) {
      # this scope orders records by their proximity to the given date.
      # if a record covers the date, it will be prioritized.
      # otherwise, it finds the record with the nearest started or finished on date.
      date = date&.to_date or next unarchived

      unarchived.order(
        Arel.sql(
          <<~SQL
            CASE
              WHEN #{table_name}.finished_on IS NULL
                THEN ABS(#{table_name}.started_on - DATE '#{date}')
              ELSE LEAST(
                ABS(#{table_name}.started_on - DATE '#{date}'),
                ABS(#{table_name}.finished_on - DATE '#{date}')
              )
            END
          SQL
        )
      ).limit(1)
    }

    # Date relative scopes
    scope :contains_today, -> { contains_date(Time.zone.today) }
    scope :starting_tomorrow_or_after, -> { started_on_or_after(Time.zone.tomorrow) }
    scope :current_or_future, -> { contains_today.or(starting_tomorrow_or_after) }
  end

  # Validations
  def period_dates_validation
    return if incomplete?

    if invalid_date_order?
      errors.add(:finished_on, "The end date must be later than the start date (#{started_on.to_fs(:govuk)})")
    end
  end

  def overlap_validation(name:)
    return if interval_archived?
    return unless valid_date_order?
    return unless has_overlap_with_unarchived_siblings?

    if unarchived_siblings.any? { |s| s.range.include?(started_on) }
      errors.add(:started_on, "Start date cannot overlap another #{name} period")
    elsif unarchived_siblings.any? { |s| s.range.include?(finished_on) } || finished_on.nil?
      errors.add(:finished_on, "End date cannot overlap another #{name} period")
    elsif unarchived_siblings.any? { |s| (s.started_on..s.finished_on).overlap?(started_on..finished_on) }
      errors.add(:base, "Period cannot overlap another #{name} period")
    end
  end

  # Actions
  def finish!(finished_on = Date.current)
    update!(finished_on:)
  end

  # Associations
  def predecessors = unarchived_siblings.started_before(started_on)

  def siblings = raise(NotImplementedError)

  def successors = finished_on ? unarchived_siblings.started_on_or_after(finished_on) : self.class.none

  # Predicates
  def valid_date_order?
    return true if incomplete?

    started_on <= finished_on
  end

  def finished?
    finished_on.present? && finished_on <= Time.zone.today
  end

  def leaving_today_or_in_future?
    finished_on.present? && finished_on >= Time.zone.today
  end

  def invalid_date_order? = !valid_date_order?

  def unfinished? = finished_on.nil?

  def contains_today? = finished_on.nil? || finished_on.future?

  def complete? = finished_on.present?

  def incomplete? = [started_on, finished_on].any?(&:blank?)

  def has_overlap_with_siblings? = has_overlap_with_unarchived_siblings?

  def has_overlap_with_unarchived_siblings? = unarchived_siblings.overlapping_with(self).exists?

  def has_predecessors? = predecessors.exists?

  def has_siblings? = unarchived_siblings.exists?

  def has_successors? = successors.exists?

  # Methods
  def last_finished_sibling
    unarchived_siblings.finished.earliest_first.last
  end

  def unarchived_siblings
    return self.class.none if interval_archived?

    siblings.unarchived
  end

  def interval_archived?
    respond_to?(:archived?) && archived?
  end
end
