module TasksIndex
  module NoQts
    class TableRowComponent < TasksIndex::BaseTableRowComponent
      def self.headings
        ["Name", "TRN", "School name", "School start date", "Induction tutor email"]
      end
    end
  end
end
