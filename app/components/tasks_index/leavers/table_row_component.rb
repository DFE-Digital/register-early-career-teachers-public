module TasksIndex
  module Leavers
    class TableRowComponent < TasksIndex::BaseTableRowComponent
      include Rails.application.routes.url_helpers

      def self.headings
        ["Name", "TRN", "Induction start date", "Recorded by", "Induction tutor name", ""]
      end

      delegate :current_or_next_induction_period, to: :teacher
      delegate :started_on, to: :current_or_next_induction_period, prefix: :induction, allow_nil: true
      delegate :appropriate_body_name, to: :current_or_next_induction_period, prefix: :current_induction_period, allow_nil: true
      delegate :induction_tutor_name, to: :school
    end
  end
end
