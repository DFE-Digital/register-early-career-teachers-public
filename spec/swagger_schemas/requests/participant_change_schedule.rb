PARTICIPANT_CHANGE_SCHEDULE_REQUEST = {
  description: "Notify that a participant is changing training schedule",
  type: :object,
  required: %w[data],
  properties: {
    data: {
      description: "The change schedule request for a participant",
      type: :object,
      required: %w[type attributes],
      properties: {
        type: {
          type: :string,
          required: true,
          enum: %w[participant-change-schedule],
          example: "participant-change-schedule",
        },
        attributes: {
          description: "A participant change schedule action",
          type: :object,
          required: %w[schedule_identifier course_identifier],
          properties: {
            schedule_identifier: {
              description: "The new schedule of the participant",
              type: :string,
              required: true,
              enum: Schedule.identifiers.keys,
              example: "ecf-extended-september",
            },
            course_identifier: {
              description: "The type of course the participant is enrolled in",
              type: :string,
              required: true,
              enum: %w[ecf-mentor ecf-induction],
              example: "ecf-mentor"
            },
            cohort: {
              description: "Providers may not change the current value for ECF participants. " \
              "Indicates which call-off contract funds this participant’s training. "\
              "2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year.",
              type: :string,
              required: false,
              example: "2021"
            }
          }
        }
      },
    }
  }
}.freeze
