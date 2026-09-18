module Admin
  module Teachers
    module UndoRegistrationWizard
      class SchoolPeriodSummaryComponent < ApplicationComponent
        attr_reader :school_period, :end_date

        def initialize(school_period:, end_date:)
          @school_period = school_period
          @end_date = end_date
        end

      private

        def school_period_type
          ect_school_period? ? "ECT" : "Mentor"
        end

        def ect_school_period?
          school_period.is_a?(ECTAtSchoolPeriod)
        end
      end
    end
  end
end
