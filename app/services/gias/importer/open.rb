module GIAS
  class Importer
    class Open
      attr_reader :gias_school

      def initialize(gias_school)
        @gias_school = gias_school
      end

      def open!
        return false unless gias_school.can_be_opened?

        ActiveRecord::Base.transaction do
          gias_school.create_school!
          record_school_opened_event!
        end

        true
      end

    private

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
