DECLARATION_POST2024_ECT_STARTED_ATTRIBUTES = {
  description: "An ECT started declaration",
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
      enum: %w[ecf-induction],
      example: "ecf-induction",
    },
    evidence_held: {
      description: "The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.",
      type: :string,
      enum: %w[training-event-attended self-study-material-completed materials-engaged-with-offline other],
      example: "training-event-attended",
    },
  },
}.freeze

DECLARATION_POST2024_ECT_RETAINED_ATTRIBUTES = {
  description: "An ECT retained declaration",
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
      enum: %w[retained-1 retained-2 retained-3 retained-4],
      example: "retained-1",
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
      enum: %w[ecf-induction],
      example: "ecf-induction",
    },
    evidence_held: {
      description: "The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period. For retained-2 declarations, providers will need to confirm if the engagement threshold has been reached and only accept either the '75-percent-engagement-met' or '75-percent-engagement-met-reduced-induction' values.",
      type: :string,
      enum: %w[training-event-attended self-study-material-completed materials-engaged-with-offline other 75-percent-engagement-met 75-percent-engagement-met-reduced-induction],
      example: "training-event-attended",
    },
  },
}.freeze

DECLARATION_POST2024_ECT_COMPLETED_ATTRIBUTES = {
  description: "An ECT completed declaration",
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
      enum: %w[ecf-induction],
      example: "ecf-induction",
    },
    evidence_held: {
      description: "The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.",
      type: :string,
      enum: %w[75-percent-engagement-met 75-percent-engagement-met-reduced-induction one-term-induction],
      example: "75-percent-engagement-met",
    },
  },
}.freeze

DECLARATION_POST2024_ECT_EXTENDED_ATTRIBUTES = {
  description: "An ECT extended declaration",
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
      enum: %w[extended-1 extended-2 extended-3],
      example: "extended-1",
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
      enum: %w[ecf-induction],
      example: "ecf-induction",
    },
    evidence_held: {
      description: "The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.",
      type: :string,
      enum: %w[training-event-attended self-study-material-completed materials-engaged-with-offline other],
      example: "training-event-attended",
    },
  },
}.freeze

DECLARATION_POST2024_ECT_DATA_REQUEST = {
  description: "A participant declaration data request for ECT participants from cohort 2025 onwards",
  type: :object,
  properties: {
    type: {
      type: :string,
      enum: %w[participant-declaration],
    },
    attributes: {
      type: :object,
      anyOf: [
        { "$ref": "#/components/schemas/DeclarationPost2024ECTStartedAttributes" },
        { "$ref": "#/components/schemas/DeclarationPost2024ECTRetainedAttributes" },
        { "$ref": "#/components/schemas/DeclarationPost2024ECTCompletedAttributes" },
        { "$ref": "#/components/schemas/DeclarationPost2024ECTExtendedAttributes" },
      ],
    },
  },
}.freeze
