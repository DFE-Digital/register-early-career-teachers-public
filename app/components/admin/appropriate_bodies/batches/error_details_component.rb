module Admin
  module AppropriateBodies
    module Batches
      class ErrorDetailsComponent < ViewComponent::Base
        attr_reader :batch

        def initialize(batch:)
          @batch = batch
        end

      private

        # @return [String]
        def caption
          "Errors (#{rows.count})"
        end

        # @return [String]
        def head
          batch.row_headings.values
        end

        # @return [Array<String>]
        def tally
          [error_count, success_rate]
        end

        # @return [String]
        def error_count
          pluralize(batch.tally[:errored_count], 'error')
        end

        # @return [String]
        def success_rate
          (batch.recorded_count / batch.tally[:uploaded_count].to_f * 100).round(1).to_s + '% success rate'
        end

        # @return [Array<String>]
        def rows
          ::AppropriateBodies::ProcessBatch::Download.new(pending_induction_submission_batch: batch).to_a
        end
      end
    end
  end
end
