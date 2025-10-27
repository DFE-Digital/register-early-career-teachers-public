PARTICIPANT_DEFER_REQUEST = {
  description: "Defer a participant from training",
  type: :object,
  required: %w[data],
  properties: {
    data: {
      description: "A participant deferral",
      type: :object,
      required: %w[type attributes],
      properties: {
        type: {
          type: :string,
          required: true,
          enum: %w[participant-defer],
          example: "participant-defer",
        },
        attributes: {
          description: "A participant deferral action",
          type: :object,
          required: %w[reason course_identifier],
          properties: {
            reason: {
              description: "The reason for the deferral",
              type: :string,
              required: true,
              enum: TrainingPeriod.deferral_reasons.keys.map(&:dasherize),
              example: "left-teaching-profession",
            },
            course_identifier: {
              description: "The type of course the participant is enrolled in",
              type: :string,
              required: true,
              enum: %w[ecf-mentor ecf-induction],
              example: "ecf-mentor"
            }
          }
        }
      },
    }
  }
}.freeze
