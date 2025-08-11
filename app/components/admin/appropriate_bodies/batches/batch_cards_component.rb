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
          (batch.tally[:errored_count] / batch.tally[:uploaded_count].to_f * 100).round(1).to_s + '%'
        end
      end
    end
  end
end
