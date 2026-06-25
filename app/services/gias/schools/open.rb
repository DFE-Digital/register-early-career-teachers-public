module GIAS
  module Schools
    class Open
      attr_reader :gias_school

      def initialize(gias_school)
        @gias_school = gias_school
      end

      def open!
        return false unless gias_school.can_be_opened?

        open_school!

        true
      end

    private

      def open_school!
        ActiveRecord::Base.transaction do
          gias_school.create_school!
          record_school_opened_event!
        end
      end

      def record_school_opened_event!
        Events::Record.record_school_opened_event!(
          school: gias_school.school,
          gias_school:,
          happened_at: gias_school.opened_on,
          author:
        )
      end

      def author
        Events::SystemAuthor.new
      end
    end
  end
end
