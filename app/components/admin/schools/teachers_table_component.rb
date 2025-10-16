module Admin
  module Schools
    class TeachersTableComponent < ApplicationComponent
      attr_reader :school

      def initialize(school:)
        @school = school
      end

      def teachers_with_roles
        @teachers_with_roles ||= all_teachers_with_roles
      end

      def latest_contract_period(teacher_data)
        teacher_data[:latest_contract_period]
      end

      private

      def teacher_full_name(teacher)
        ::Teachers::Name.new(teacher).full_name
      end

      def all_teachers_with_roles
        all_school_teachers.map do |teacher|
          {
            teacher:,
            latest_contract_period: current_year
          }
        end
      end

      def all_school_teachers
        (school.ect_teachers + school.mentor_teachers).uniq
      end

      def current_year
        Date.current.year
      end
    end
  end
end
