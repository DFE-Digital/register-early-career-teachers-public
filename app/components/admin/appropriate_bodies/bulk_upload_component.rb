module Admin
  module AppropriateBodies
    class BulkUploadComponent < ViewComponent::Base
      renders_one :batch_details, -> {
        ::Admin::AppropriateBodies::Batches::BatchDetailsComponent.new(batch:)
      }

      renders_one :error_details, -> {
        ::Admin::AppropriateBodies::Batches::ErrorDetailsComponent.new(batch:)
      }

      renders_one :induction_details, -> {
        ::Admin::AppropriateBodies::Batches::InductionDetailsComponent.new(batch:)
      }

      attr_reader :batch

      def initialize(batch:)
        @batch = batch
      end
    end
  end
end
