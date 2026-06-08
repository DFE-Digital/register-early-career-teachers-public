module GIAS
  module Schools
    class Open
      attr_reader :gias_school

      def initialize(gias_school)
        @gias_school = gias_school
      end

      def self.call
        GIAS::School.openable.find_each do |gias_school|
          new(gias_school).open!
        end
      end

      def open!
        return unless gias_school.open?
        return if gias_school.predecessors.exists?
        return if gias_school.successors.exists?
        return if already_opened?

        ActiveRecord::Base.transaction do
          gias_school.create_school!
          record_school_opened_event!
        end
      end

    private

      def record_school_opened_event!
        # Events::SchoolOpened.create!(
        #   school:,
        #   author:
        # )
      end

      def already_opened?
        gias_school.school.present?
      end

      def author
        @author ||= Events::SystemAuthor.new
      end
    end
  end
end
