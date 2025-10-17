PARTICIPANT_ID_CHANGE = {
  description: "The details of a participant ID change",
  type: :object,
  required: %i[
    from_participant_id
    to_participant_id
    changed_at
  ],
  properties: {
    from_participant_id: {
      description: "The unique identifier of the changed from participant training record",
      type: :string,
      format: :uuid,
      example: "23dd8d66-e11f-4139-9001-86b4f9abcb02"
    },
    to_participant_id: {
      description: "The unique identifier of the changed to participant training record",
      type: :string,
      format: :uuid,
      example: "ac3d1243-7308-4879-942a-c4a70ced400a"
    },
    changed_at: {
      description: "The date and time the participant ID change was made",
      type: :string,
      format: :date_time,
      example: "2023-01-01T12:00:00Z"
    }
  }
}.freeze
