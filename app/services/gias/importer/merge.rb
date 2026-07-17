module GIAS
  class Importer
    class Merge
      attr_reader :gias_school

      def initialize(gias_school)
        @gias_school = gias_school
      end

      def merge!
        return false unless gias_school.can_be_merged?

        ActiveRecord::Base.transaction do
          mentor_teachers.each do |teacher|
            overlapping_mentor_at_school_periods(teacher).each do |periods|
              GIAS::Importer::MentorAtSchoolPeriods::Merge.call(periods:, predecessor_school:, successor_school:)
            end
          end

          remaining_mentor_periods = school.mentor_at_school_periods.reload

          remaining_mentor_periods.each do |mentor_at_school_period|
            GIAS::Importer::MentorAtSchoolPeriods::Transfer.call(mentor_at_school_period:, predecessor_school:, successor_school:)
          end

          remaining_ect_periods = school.ect_at_school_periods.reload

          remaining_ect_periods.each do |ect_at_school_period|
            GIAS::Importer::ECTAtSchoolPeriods::Transfer.call(ect_at_school_period:, predecessor_school:, successor_school:)
          end

          record_school_merged_event!
        end

        true
      end

    private

      def overlapping_mentor_at_school_periods(teacher)
        GIAS::Importer::MentorAtSchoolPeriods::Overlapping.find(teacher:, schools:)
      end

      def record_school_merged_event!
        Events::Record.record_school_merged_event!(
          school: successor_school,
          successor_gias_school: successor,
          predecessor_gias_school: gias_school,
          happened_at: closed_on,
          author:
        )
      end

      def author
        Events::SystemAuthor.new
      end

      def schools = [school, successor_school]
      def predecessor_school = school

      def successor_school
        @successor_school ||= successor.school
      end

      delegate :school, :closed_on, :successor, to: :gias_school
      delegate :mentor_teachers, to: :school, prefix: false
    end
  end
end
