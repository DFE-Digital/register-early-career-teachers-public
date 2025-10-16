module Admin
  module AppropriateBodies
    module Batches
      class BatchDetailsComponent < ApplicationComponent
        attr_reader :batch

        def initialize(batch:)
          @batch = batch
        end

        private

        delegate :batch_status_tag, to: :helpers

        # @return [String]
        def title
          "#{batch.batch_type.titleize} ##{batch.id}"
        end

        # @return [Array<Hash>]
        def rows
          [
            {key: {text: "File name"}, value: {text: batch.file_name}},
            {key: {text: "Submitted"}, value: {text: date_submitted}},
            {key: {text: "Completed"}, value: {text: date_completed}},
            {key: {text: "Status"}, value: {text: batch_status_tag(batch)}}
          ]
        end

        # @return [String]
        def date_submitted
          return "Unknown" if bulk_upload_started_event.blank?

          bulk_upload_started_event.happened_at.to_fs(:govuk)
        end

        # @return [String]
        def date_completed
          return "Cannot be completed" if batch.processed? && batch.no_valid_data?
          return "Not yet completed" unless batch.completed?
          return "Unknown" if bulk_upload_completed_event.blank?

          bulk_upload_completed_event.happened_at.to_fs(:govuk)
        end

        # @return [Event, nil]
        def bulk_upload_started_event
          Event.find_by(pending_induction_submission_batch_id: batch.id, event_type: "bulk_upload_started")
        end

        # @return [Event, nil]
        def bulk_upload_completed_event
          Event.find_by(pending_induction_submission_batch_id: batch.id, event_type: "bulk_upload_completed")
        end
      end
    end
  end
end
