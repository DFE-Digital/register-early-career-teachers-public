class API::ParticipantSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:full_name) { |teacher, _options| Teachers::Name.new(teacher).full_name }
    field(:trn, name: :teacher_reference_number)
    field(:api_updated_at, name: :updated_at)

    field(:ecf_enrolments) do |_teacher, _options|
      []
    end

    field(:participant_id_changes) do |teacher, _options|
      (teacher.participant_id_changes || []).map do |participant_id_change|
        API::ParticipantIdChangeSerializer.render_as_hash(participant_id_change)
      end
    end
  end

  identifier :ecf_user_id, name: :id
  field(:type) { "participant" }

  association :attributes, blueprint: AttributesSerializer do |participant|
    participant
  end
end
