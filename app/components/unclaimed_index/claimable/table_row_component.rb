module UnclaimedIndex
  module Claimable
    class TableRowComponent < UnclaimedIndex::BaseTableRowComponent
      include Rails.application.routes.url_helpers

      def self.headings
        ["Name", "TRN", "School name", "School start date", "Induction tutor email", "ITT provider", ""]
      end

      delegate :trs_initial_teacher_training_provider_name, to: :ect_at_school_period
    end
  end
end
