# Send selected bulk upload Event records to DfE Analytics that connect Teachers to their Induction Periods.
class AnalyticsBatchJob < ApplicationJob
  queue_as :dfe_analytics

  # @return [Array<Symbol>]
  EVENT_FIELDS = %i[
    author_type
    created_at
    event_type
    happened_at
    id
    induction_period_id
    pending_induction_submission_batch_id
    teacher_id
  ].freeze

  # @param pending_induction_submission_batch_id [Integer]
  # @return [nil]
  def perform(pending_induction_submission_batch_id:)
    events = Event
      .where.not(induction_period_id: nil)
      .where(pending_induction_submission_batch_id:)
      .select(*EVENT_FIELDS)

    events.map do |db_event|
      data = db_event.attributes
      event = DfE::Analytics::Event.new
                                   .with_type(:bulk_upload_action)
                                   .with_entity_table_name(:bulk_upload_actions)
                                   .with_data(data:)

      DfE::Analytics::SendEvents.do(Array.wrap(event.as_json))
    end
  end
end
