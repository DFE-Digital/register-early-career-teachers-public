module UnclaimedIndex
  module ClaimedByAnother
    class TableRowComponent < UnclaimedIndex::BaseTableRowComponent
      def self.headings
        ["Name", "TRN", "School name", "School start date", "Induction tutor email", "Current AB"]
      end

      delegate :current_or_next_induction_period, to: :teacher
      delegate :appropriate_body_name, to: :current_or_next_induction_period, prefix: :current_induction_period, allow_nil: true
    end
  end
end
