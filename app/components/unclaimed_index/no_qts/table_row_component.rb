module UnclaimedIndex
  module NoQts
    class TableRowComponent < UnclaimedIndex::BaseTableRowComponent
      def self.headings
        ["Name", "TRN", "School name", "School start date", "Induction tutor email"]
      end
    end
  end
end
