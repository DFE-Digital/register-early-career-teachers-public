class RecordEventJob < ApplicationJob
  queue_as :events

  def deserialize_arguments(serialized_args)
    ActiveJob::Arguments.deserialize(serialized_args)
  rescue ActiveJob::DeserializationError => e
    # Error while trying to deserialize arguments: Couldn't find SchoolPartnership with 'id'="21556"
    raise e unless e.cause.message.include?("Couldn't find")

    # Remove the missing record from the args
    missing_model_name = e.cause.message
      .split("Couldn't find ").second
      .split(" ").first
      .underscore
    serialized_args.first.delete(missing_model_name)

    # Remove `old_` record from the metadata args
    if serialized_args.first.key?("metadata")
      missing_metadata_key = "old_#{missing_model_name}"
      serialized_args.first["metadata"].delete(missing_metadata_key)
    end

    ActiveJob::Arguments.deserialize(serialized_args)
  end

  def perform(event_arguments)
    event_arguments.transform_keys! do |key|
      case
      when key.to_sym == :email
        :author_email
      when key.to_sym == :name
        :author_name
      when key.to_sym == :appropriate_body_id
        :appropriate_body_period_id
      else
        key
      end
    end
    Event.create!(event_arguments)
  end
end
