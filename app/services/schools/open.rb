module Schools
  class Open
    def self.call
      GIAS::School.open_status.without_predecessors.without_schools.find_each do |gias_school|
        new(gias_school).open!
      end
    end

    def open!
      return unless gias_school.open?
      return if gias_school.predecessors.exists?
      return if gias_school.school.present?

      open_school!

      record_school_opened_event!
    end

    private
      def open_school!
        gias_school.create_school!
      end

      def record_school_opened_event!
        Events::SchoolOpened.create!(
          school:,
          author:
        )
      end

      def author
        @author ||= Events::SystemAuthor.new
      end
  end
end
