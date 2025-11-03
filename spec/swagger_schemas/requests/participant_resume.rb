PARTICIPANT_RESUME_REQUEST = {
  description: "Resume a participant's training",
  type: :object,
  required: %w[data],
  properties: {
    data: {
      description: "A participant resumption",
      type: :object,
      required: %w[type attributes],
      properties: {
        type: {
          type: :string,
          required: true,
          enum: %w[participant-resume],
          example: "participant-resume",
        },
        attributes: {
          description: "A participant resumption action",
          type: :object,
          required: %w[course_identifier],
          properties: {
            course_identifier: {
              description: "The type of course the participant is enrolled in",
              type: :string,
              required: true,
              enum: %w[ecf-mentor ecf-induction],
              example: "ecf-mentor"
            }
          }
        }
      }
    }
  }
}.freeze
