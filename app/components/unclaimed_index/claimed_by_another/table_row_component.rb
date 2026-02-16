module UnclaimedIndex
  module ClaimedByAnother
    class TableRowComponent < UnclaimedIndex::BaseTableRowComponent
      def self.headings
        ["Name", "TRN", "School name", "School start date", "Induction tutor email", "Current AB"]
      end

    private

      def current_induction_period_appropriate_body_name
        ect_at_school_period.teacher.current_or_next_induction_period&.appropriate_body_name
      end
    end
  end
end
