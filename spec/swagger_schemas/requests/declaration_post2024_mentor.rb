DECLARATION_POST2024_MENTOR_STARTED_ATTRIBUTES = {
  description: "A mentor started declaration",
  type: :object,
  required: %i[participant_id declaration_type declaration_date course_identifier],
  additionalProperties: false,
  properties: {
    participant_id: {
      description: "The unique ID of the participant",
      type: :string,
      format: :uuid,
      example: "3452b1a6-cbaa-422f-9ca9-40afa28583a2",
    },
    declaration_type: {
      description: "The event declaration type",
      type: :string,
      enum: %w[started],
      example: "started",
    },
    declaration_date: {
      description: "The event declaration date",
      type: :string,
      format: :"date-time",
      example: "2021-05-31T02:21:32.000Z",
    },
    course_identifier: {
      description: "The type of course the participant is enrolled in",
      type: :string,
      enum: %w[ecf-mentor],
      example: "ecf-mentor",
    },
    evidence_held: {
      description: "The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.",
      type: :string,
      enum: %w[training-event-attended self-study-material-completed materials-engaged-with-offline other],
      example: "training-event-attended",
    },
  },
}.freeze

DECLARATION_POST2024_MENTOR_COMPLETED_ATTRIBUTES = {
  description: "A mentor completed declaration",
  type: :object,
  required: %i[participant_id declaration_type declaration_date course_identifier evidence_held],
  additionalProperties: false,
  properties: {
    participant_id: {
      description: "The unique ID of the participant",
      type: :string,
      format: :uuid,
      example: "3452b1a6-cbaa-422f-9ca9-40afa28583a2",
    },
    declaration_type: {
      description: "The event declaration type",
      type: :string,
      enum: %w[completed],
      example: "completed",
    },
    declaration_date: {
      description: "The event declaration date",
      type: :string,
      format: :"date-time",
      example: "2021-05-31T02:21:32.000Z",
    },
    course_identifier: {
      description: "The type of course the participant is enrolled in",
      type: :string,
      enum: %w[ecf-mentor],
      example: "ecf-mentor",
    },
    evidence_held: {
      description: "The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.",
      type: :string,
      enum: %w[75-percent-engagement-met 75-percent-engagement-met-reduced-induction],
      example: "75-percent-engagement-met",
    },
  },
}.freeze

DECLARATION_POST2024_MENTOR_DATA_REQUEST = {
  description: "A participant declaration data request for mentor participants from cohort 2025 onwards",
  type: :object,
  properties: {
    type: {
      type: :string,
      enum: %w[participant-declaration],
    },
    attributes: {
      type: :object,
      anyOf: [
        { "$ref": "#/components/schemas/DeclarationPost2024MentorStartedAttributes" },
        { "$ref": "#/components/schemas/DeclarationPost2024MentorCompletedAttributes" },
      ],
    },
  },
}.freeze
