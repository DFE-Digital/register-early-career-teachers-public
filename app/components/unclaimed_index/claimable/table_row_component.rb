module UnclaimedIndex
  module Claimable
    class TableRowComponent < UnclaimedIndex::BaseTableRowComponent
      include Rails.application.routes.url_helpers

      def self.headings
        ["Name", "TRN", "School name", "School start date", "Induction tutor email", "ITT provider", ""]
      end

    private

      def trs_initial_teacher_training_provider_name
        ect_at_school_period.trs_initial_teacher_training_provider_name
      end
    end
  end
end
