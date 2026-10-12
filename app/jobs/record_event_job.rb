class RecordEventJob < ApplicationJob
  queue_as :events

  def deserialize_arguments(serialized_args)
    ActiveJob::Arguments.deserialize(serialized_args)
  rescue ActiveJob::DeserializationError => e
    # Error while trying to deserialize arguments: Couldn't find SchoolPartnership with 'id'="21556"
    missing_model_name = e.message
      .split("Couldn't find ").second
      .split(" ").first
      .underscore
    serialized_args.first.delete(missing_model_name)
    ActiveJob::Arguments.deserialize(serialized_args)
  end

  def perform(...)
    Event.create!(...)
  end
end
