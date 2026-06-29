module GIAS
  module Schools
    class Merge
      attr_reader :gias_school

      def initialize(gias_school)
        @gias_school = gias_school
      end

      def merge!
        return false unless gias_school.can_be_merged?

        merge_school!

        true
      end

    private

      def merge_school!
        ActiveRecord::Base.transaction do
          move_unstarted_mentorship_periods!
          move_unstarted_periods!
          split_ongoing_periods!
  
          
          record_school_merged_event!
        end
      end

      def move_unstarted_mentorship_periods!
      end

      def move_unstarted_periods!
      end

      def split_ongoing_periods!
      end

      def record_school_merged_event!
        Events::Record.record_school_merged_event!(
          school: gias_school.school,
          gias_school:,
          happened_at: gias_school.closed_on,
          author:
        )
      end

      def author
        Events::SystemAuthor.new
      end
    end
  end
end
