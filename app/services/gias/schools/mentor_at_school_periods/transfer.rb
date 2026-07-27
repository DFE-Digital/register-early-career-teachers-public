module GIAS::Schools
  module MentorAtSchoolPeriods
    class Transfer
      def self.call(...) = new(...).call

      def initialize(mentor_at_school_period:, predecessor_school:, successor_school:)
        @mentor_at_school_period = mentor_at_school_period
        @successor_school = successor_school
        @predecessor_school = predecessor_school
      end

      def call
        return unless predecessor_school == mentor_at_school_period.school

        ActiveRecord::Base.transaction do
          update_mentor_at_school_period!
          update_training_periods!
          update_events!
          update_mentorship_periods!

          record_event!
        end
      end

    private

      attr_reader :mentor_at_school_period, :predecessor_school, :successor_school

      def update_mentor_at_school_period!
        mentor_at_school_period.update!(school: successor_school)
      end

      def update_training_periods!
        training_periods.where.associated(:school_partnership).each do |training_period|
          new_partnership = successor_partnership(training_period.school_partnership)
          training_period.update!(school_partnership: new_partnership)
        end
      end

      def update_events!
        events.where.associated(:school_partnership).each do |event|
          new_partnership = successor_partnership(event.school_partnership)
          event.update!(school_partnership: new_partnership)
        end

        events.where.associated(:school).each do |event|
          event.update!(school: successor_school)
        end
      end

      def update_mentorship_periods!
        mentorship_periods.each do |mentorship_period|
          GIAS::Schools::ECTAtSchoolPeriods::Transfer.call(ect_at_school_period: mentorship_period.mentee, predecessor_school:, successor_school:)
        end
      end

      def successor_partnership(predecessor_school_partnership)
        GIAS::Schools::SchoolPartnerships::Transfer.call(predecessor_school_partnership:, successor_school:)
      end

      def record_event!
        Events::Record.record_teacher_mentor_at_school_period_moved_school!(
          teacher:,
          mentor_at_school_period:,
          old_school_name_and_urn:,
          new_school: successor_school,
          happened_at: predecessor_gias_school.closed_on,
          author:
        )
      end

      def predecessor_gias_school = predecessor_school.gias_school
      def old_school_name_and_urn = ::Schools::Name.new(predecessor_school).name_and_urn

      delegate :mentorship_periods, :training_periods, :events, :teacher, to: :mentor_at_school_period

      def author = Events::SystemAuthor.new
    end
  end
end
