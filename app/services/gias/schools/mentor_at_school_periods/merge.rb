module GIAS::Schools
  module MentorAtSchoolPeriods
    class Merge
      def self.call(...) = new(...).call

      def initialize(periods:, predecessor_school:, successor_school:)
        @periods = periods
        @predecessor_school = predecessor_school
        @successor_school = successor_school
      end

      def call
        ActiveRecord::Base.transaction do
          successor_period.assign_attributes(started_on:, finished_on:)

          update_mentorship_periods!
          update_training_periods!
          update_events!

          redundant_periods.each do |period|
            period.training_periods.reset
            period.mentorship_periods.reset
            period.events.reset
            period.destroy!
          end

          successor_period.save!

          record_event!
        end
      end

    private

      attr_reader :periods, :predecessor_school, :successor_school

      def successor_period
        @successor_period ||= periods
          .select { |period| period.school == successor_school }
          .max_by(&:started_on)
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

      def update_training_periods!
        training_periods.each do |training_period|
          if training_period.school_partnership.present?
            training_period.school_partnership = successor_partnership(training_period.school_partnership)
          end
          training_period.mentor_at_school_period = successor_period
          training_period.save!
        end
      end

      def update_mentorship_periods!
        mentorship_periods.each do |mentorship_period|
          GIAS::Schools::ECTAtSchoolPeriods::Transfer.call(ect_at_school_period: mentorship_period.mentee, predecessor_school:, successor_school:)
          mentorship_period.mentor = successor_period
          mentorship_period.save!
        end
      end

      def update_events!
        events.each do |event|
          if event.school_partnership.present?
            event.school_partnership = successor_partnership(event.school_partnership)
          end
          event.school = successor_school if event.school.present?
          event.mentor_at_school_period = successor_period
          event.save!
        end
      end

      def successor_partnership(predecessor_school_partnership)
        GIAS::Schools::SchoolPartnerships::Transfer.call(predecessor_school_partnership:, successor_school:)
      end

      def finished_on
        @finished_on ||= calculate_finished_on
      end

      def calculate_finished_on
        return nil if periods.any?(&:ongoing?)

        periods.map(&:finished_on).compact.max
      end

      def started_on
        @started_on ||= periods.map(&:started_on).min
      end

      def record_event!
        Events::Record.record_teacher_mentor_at_school_periods_merged!(
          teacher: successor_period.teacher,
          successor_period:,
          mentor_at_school_periods: periods,
          happened_at: predecessor_school.gias_school.closed_on,
          author:
        )
      end

      def author = Events::SystemAuthor.new
    end
  end
end
