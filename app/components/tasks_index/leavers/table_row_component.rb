module TasksIndex
  module Leavers
    class TableRowComponent < TasksIndex::BaseTableRowComponent
      include Rails.application.routes.url_helpers

      def self.headings
        ["Name", "TRN", "Recorded by", "Induction tutor name", ""]
      end

      delegate :induction_tutor_name, to: :school
      delegate :ect_at_school_periods, to: :teacher
      delegate :unfinished, to: :ect_at_school_periods, prefix: true

      def recorded_by_school_name
        ect_at_school_periods_unfinished.first&.school_name || school_name
      end
    end
  end
end
