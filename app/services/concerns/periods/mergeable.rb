module Periods
  module Mergeable
    extend ActiveSupport::Concern

    class_methods do
      def call(...) = new(...).call
    end

    def initialize(periods:, destination:)
      @periods = periods
      @destination = destination
    end

    def call
      ActiveRecord::Base.transaction do
        successor_period.assign_attributes(started_on:, finished_on:)

        update_related_records!

        redundant_periods.each do |period|
          reset_related_records!(period)
          period.destroy!
        end

        successor_period.save!

        record_event!
      end
    end

  private

    attr_reader :periods, :destination

    # Periods to merge are provided by the Overlapping service, and always include
    # at least one period from the destination that the others will be merged into.
    def successor_period
      @successor_period ||= periods
        .select { |period| period.teacher == destination }
        .max_by(&:started_on)
    end

    def period_type
      raise NotImplementedError, "Subclasses must define the period_type method"
    end

    def redundant_periods
      @redundant_periods ||= periods.excluding(successor_period)
    end

    def events
      @events ||= redundant_periods.flat_map(&:events).uniq
    end

    def attrs
      { period_type => successor_period }
    end

    def update_related_records!
      move_events!
    end

    def move_events!
      events.each { |event| event.update!(attrs) }
    end

    def reset_related_records!(period)
      period.events.reset
    end

    def finished_on
      @finished_on ||= calculate_finished_on
    end

    def calculate_finished_on
      return nil if periods.any?(&:unfinished?)

      periods.map(&:finished_on).compact.max
    end

    def started_on
      @started_on ||= periods.map(&:started_on).min
    end

    def record_event!
      Events::Record.public_send(
        event_name,
        teacher:,
        successor_period:,
        periods:,
        author:
      )
    end

    def teacher
      successor_period.teacher
    end

    def event_name
      "record_teacher_#{period_type.to_s.pluralize}_merged!"
    end

    def author = Events::SystemAuthor.new
  end
end
