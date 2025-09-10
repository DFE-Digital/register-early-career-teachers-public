class API::ParticipantIdChangeSerializer < Blueprinter::Base
  field(:from_participant_id)
  field(:to_participant_id)
  field(:created_at, name: :changed_at)
end
