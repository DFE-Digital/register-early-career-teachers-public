module Teachers
  class MergeTRN
    class Merge
      class CannotMergePeriods < StandardError; end

      def self.call(...) = new(...).call

      def initialize(periods:, destination:)
        @periods = periods
        @destination = destination
      end

      def call
        raise ArgumentError, "Periods must be of the same type" if different_period_types?
        raise CannotMergePeriods, "Periods have different training programmes" if periods_have_different_training_programmes?
        raise CannotMergePeriods, "Periods have different schedules" if periods_have_different_schedules?
        raise CannotMergePeriods, "Periods have different partnerships" if periods_have_different_partnerships?

        ActiveRecord::Base.transaction do
          successor_period.update!(started_on:, finished_on:)

          successor_period.reload

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

      def period_types
        periods.map(&:class).uniq
      end

      def different_period_types?
        period_types.size > 1
      end

      def period_type
        @period_type ||= period_types.first.to_s.underscore.to_sym
      end

      def training_period?
        period_type == :training_period
      end

      def periods_have_different_partnerships?
        return unless training_period?

        periods.map(&:school_partnership).uniq.size > 1
      end

      def periods_have_different_training_programmes?
        return unless training_period?

        periods.map(&:training_programme).uniq.size > 1
      end

      def periods_have_different_schedules?
        return unless training_period?

        periods.map(&:schedule).uniq.size > 1
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

      def declarations
        @declarations ||= redundant_periods.flat_map(&:declarations).uniq
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

      def update_related_records!
        case period_type
        when :mentor_at_school_period, :ect_at_school_period
          update_mentorship_periods!
          update_training_periods!
        when :training_period
          move_declarations!
        end

        move_events!
      end

      def update_mentorship_periods!
        return unless at_school_period?

        mentorship_periods.each { |period| period.update!(mentorship_attrs) }
      end

      def update_training_periods!
        return unless at_school_period?

        overlapping_training_periods.each do |periods|
          Teachers::MergeTRN::Merge.call(periods:, destination:)
        end

        merged_training_periods = overlapping_training_periods.flat_map(&:itself).uniq

        training_periods.each do |period|
          next if merged_training_periods.include?(period)

          period.update!(attrs)
        end
      end

      def overlapping_training_periods
        @overlapping_training_periods ||= Teachers::MergeTRN::Overlapping.find(periods: source_and_destination_training_periods)
      end

      def source_and_destination_training_periods
        training_periods + successor_period.training_periods
      end

      def move_declarations!
        declarations.each { |declaration| declaration.update!(attrs) }
      end

      def move_events!
        events.each { |event| event.update!(attrs) }
      end

      def reset_related_records!(period)
        case period_type
        when :mentor_at_school_period, :ect_at_school_period
          period.training_periods.reset
          period.mentorship_periods.reset
        when :training_period
          period.declarations.reset
        end

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
