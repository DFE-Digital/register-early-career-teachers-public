module Admin
  module AppropriateBodies
    module Batches
      class BatchCardsComponent < ViewComponent::Base
        attr_reader :batch

        def initialize(batch:)
          @batch = batch
        end

      private

        def error_rate
          ratio = batch.tally[:errored_count] / batch.tally[:uploaded_count].to_f * 100
          number_to_percentage(ratio, precision: 1)
        end
      end
    end
  end
end
