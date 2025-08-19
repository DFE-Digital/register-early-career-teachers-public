module Admin
  module AppropriateBodies
    class BulkUploadComponent < ViewComponent::Base
      renders_one :batch_cards,       -> { Batches::BatchCardsComponent.new(batch:) }         # coloured cards
      renders_one :batch_details,     -> { Batches::BatchDetailsComponent.new(batch:) }       # summary list
      renders_one :error_details,     -> { Batches::ErrorDetailsComponent.new(batch:) }       # table (needs pagination?)
      renders_one :induction_details, -> { Batches::InductionDetailsComponent.new(batch:) }   # table (needs pagination?)

      attr_reader :batch

      def initialize(batch:)
        @batch = batch
      end
    end
  end
end
