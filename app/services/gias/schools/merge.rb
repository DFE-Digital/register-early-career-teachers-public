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
          move_unstarted_periods!
          split_ongoing_periods!
  
          
          record_school_merged_event!
        end
      end

      def move_unstarted_periods!
      end

      def split_ongoing_periods!
      end

      def recreate_confirmed_partnerships!
        partnerships_to_recreate.each do |school_partnership|
          SchoolPartnerships::Move(school_partnership:, new_school:, author:).call!
        end
      end

      def move_unstarted_periods!
        mentor_at_school_periods.started_after(closed_on).each do |mentor_at_school_period|
          mentor_at_school_period.update!(school: new_school)
        end
  
        ect_at_school_periods.started_after(closed_on).each do |ect_at_school_period|
          ect_at_school_period.update!(school: new_school)
        end
      end

      def ongoing_periods
        mentor_at_school_periods.ongoing_on(closed_on) + ect_at_school_periods.ongoing_on(closed_on)
      end

      def partnerships_to_recreate
        ongoing_periods.school_partnerships.distinct
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

      def new_school
        gias_school.successor.school
      end
    end
  end
end
