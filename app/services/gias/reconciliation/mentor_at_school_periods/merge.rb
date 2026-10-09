module GIAS::Reconciliation
  module MentorAtSchoolPeriods
    class Merge
      include Periods::Mergeable

      def initialize(periods:, predecessor_school:, successor_school:)
        @periods = periods
        @predecessor_school = predecessor_school
        @successor_school = successor_school
      end

    private

      attr_reader :periods, :predecessor_school, :successor_school

      def period_type
        :mentor_at_school_period
      end

      # Periods to merge are provided by the Overlapping service, and always include
      # at least one period from the successor school that the others will be merged into.
      def successor_period
        @successor_period ||= periods
          .select { |period| period.school == successor_school }
          .max_by(&:started_on)
      end

      def training_periods
        @training_periods ||= redundant_periods.flat_map(&:training_periods).uniq
      end

      def mentorship_periods
        @mentorship_periods ||= redundant_periods.flat_map(&:mentorship_periods).uniq
      end

      def update_related_records!
        update_mentorship_periods!
        update_training_periods!

        super
      end

      def reset_related_records!(period)
        period.training_periods.reset
        period.mentorship_periods.reset

        super
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
          ECTAtSchoolPeriods::Transfer.call(ect_at_school_period: mentorship_period.mentee, predecessor_school:, successor_school:)
          mentorship_period.mentor = successor_period
          mentorship_period.save!
        end
      end

      def move_events!
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
        SchoolPartnerships::Transfer.call(predecessor_school_partnership:, successor_school:)
      end

      def record_event!
        Events::Record.record_teacher_mentor_at_school_periods_merged!(
          teacher: successor_period.teacher,
          successor_period:,
          periods:,
          happened_at: predecessor_school.gias_school.closed_on,
          author:
        )
      end
    end
  end
end
