PARTICIPANT_WITHDRAW_REQUEST = {
  description: "Withdraw a participant from training",
  type: :object,
  required: %w[data],
  properties: {
    data: {
      description: "A participant withdrawal",
      type: :object,
      required: %w[type attributes],
      properties: {
        type: {
          type: :string,
          required: true,
          enum: %w[participant],
          example: "participant",
        },
        attributes: {
          description: "A participant withdrawal action",
          type: :object,
          required: %w[reason course_identifier],
          properties: {
            reason: {
              description: "The reason for the withdrawal",
              type: :string,
              required: true,
              enum: TrainingPeriod.withdrawal_reasons.keys.map(&:dasherize),
              example: "left-teaching-profession",
            },
            course_identifier: {
              description: "The type of course the participant is enrolled in",
              type: :string,
              required: true,
              enum: API::Concerns::Teachers::SharedAction::COURSE_IDENTIFIERS,
              example: "ecf-mentor"
            }
          }
        }
      },
    }
  }
}.freeze
