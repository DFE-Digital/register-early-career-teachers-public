module Admin
  module AppropriateBodies
    module Batches
      class ErrorDetailsComponent < ApplicationComponent
        attr_reader :batch

        def initialize(batch:)
          @batch = batch
        end

        # @return [Boolean]
        def render?
          batch.errored?
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
        def rows
          ::AppropriateBodies::ProcessBatch::Download.new(pending_induction_submission_batch: batch).to_a
        end
      end
    end
  end
end
