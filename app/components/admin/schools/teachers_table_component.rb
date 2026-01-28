module Admin
  module Schools
    class TeachersTableComponent < ApplicationComponent
      attr_reader :school

      def initialize(school:)
        @school = school
      end

      def teachers
        (school.ect_teachers + school.mentor_teachers).uniq
      end

      def contract_period_text(teacher)
        tp = latest_training_period_for(teacher)

        if tp.nil?
          govuk_visually_hidden("No training period")
        else
          tp.contract_period&.year || tp.expression_of_interest_contract_period&.year
        end
      end

    private

      def latest_training_period_for(teacher)
        at_school_periods = teacher.ect_at_school_periods.for_school(school.id) +
          teacher.mentor_at_school_periods.for_school(school.id)

        at_school_periods.filter_map(&:latest_training_period).max_by(&:started_on)
      end
    end
  end
end
