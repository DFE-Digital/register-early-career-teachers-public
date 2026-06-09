module GIAS
  module Schools
    class Open
      attr_reader :gias_school

      def initialize(gias_school)
        @gias_school = gias_school
      end

      def open!
        return unless gias_school.open?
        return if gias_school.predecessors.any?
        return if gias_school.successors.any?
        return if school_already_opened?

        ActiveRecord::Base.transaction do
          gias_school.create_school!
          record_school_opened_event!
        end
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

      def school_already_opened?
        gias_school.school.present?
      end

      def author
        Events::SystemAuthor.new
      end
    end
  end
end
