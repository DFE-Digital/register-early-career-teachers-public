module Teachers
  class MergeTRN
    class Merge
      def self.call(...) = new(...).call

      def initialize(periods:, destination:)
        @periods = periods
        @destination = destination
      end

      def call
        raise ArgumentError, "Periods must be of the same type" if different_period_types?

        ActiveRecord::Base.transaction do
          successor_period.assign_attributes(started_on:, finished_on:)

          update_mentorship_periods!
          update_training_periods!
          update_events!
          redundant_periods.each do |period|
            if at_school_period?
              period.training_periods.reset
              period.mentorship_periods.reset
            end
            period.events.reset
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

      def period_types
        periods.map(&:class).uniq
      end

      def different_period_types?
        period_types.size > 1
      end

      def period_type
        period_types.first.to_s.underscore.to_sym
      end

      def at_school_period?
        %i[mentor_at_school_period ect_at_school_period].include?(period_type)
      end

      def redundant_periods
        @redundant_periods ||= periods.excluding(successor_period)
      end

      def training_periods
        @training_periods ||= redundant_periods.flat_map(&:training_periods).uniq
      end

      def mentorship_periods
        @mentorship_periods ||= redundant_periods.flat_map(&:mentorship_periods).uniq
      end

      def events
        @events ||= redundant_periods.flat_map(&:events).uniq
      end

      def attrs
        { period_type => successor_period }
      end

      def mentorship_attrs
        attribute_name = period_type == :ect_at_school_period ? :mentee : :mentor

        { attribute_name => successor_period }
      end

      def update_mentorship_periods!
        return unless at_school_period?

        mentorship_periods.each { |period| period.update!(mentorship_attrs) }
      end

      def update_training_periods!
        return unless at_school_period?

        training_periods.each { |period| period.update!(attrs) }
      end

      def update_events!
        events.each { |event| event.update!(attrs) }
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
        Events::Record.send(
          event_method,
          teacher:,
          successor_period:,
          periods:,
          author:
        )
      end

      def teacher
        successor_period.teacher
      end

      def event_method
        "record_teacher_#{period_type.to_s.pluralize}_merged!"
      end

      def author = Events::SystemAuthor.new
    end
  end
end
