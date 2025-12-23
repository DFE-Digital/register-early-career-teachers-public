DECLARATION_PRE2025_STARTED_ATTRIBUTES = {
  description: "An ECF started participant declaration",
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
      enum: %w[ecf-induction ecf-mentor],
      example: "ecf-induction",
    },
  },
}.freeze

DECLARATION_PRE2025_RETAINED_ATTRIBUTES = {
  description: "An ECF participant retained declaration",
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
      enum: %w[ecf-induction ecf-mentor],
      example: "ecf-induction",
    },
    evidence_held: {
      description: "The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.",
      type: :string,
      enum: %w[training-event-attended self-study-material-completed other],
      example: "training-event-attended",
    },
  },
}.freeze

DECLARATION_PRE2025_COMPLETED_ATTRIBUTES = {
  description: "An ECF completed participant declaration",
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
      enum: %w[ecf-induction ecf-mentor],
      example: "ecf-induction",
    },
    evidence_held: {
      description: "The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.",
      type: :string,
      enum: %w[training-event-attended self-study-material-completed other],
      example: "training-event-attended",
    },
  },
}.freeze

DECLARATION_PRE2025_EXTENDED_ATTRIBUTES = {
  description: "An ECF extended participant declaration",
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
      enum: %w[ecf-induction ecf-mentor],
      example: "ecf-induction",
    },
    evidence_held: {
      description: "The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.",
      type: :string,
      enum: %w[training-event-attended self-study-material-completed other],
      example: "training-event-attended",
    },
  },
}.freeze

DECLARATION_PRE2025_DATA_REQUEST = {
  description: "A participant declaration data request for participants in cohort 2024 and previous years",
  type: :object,
  properties: {
    type: {
      type: :string,
      enum: %w[participant-declaration],
    },
    attributes: {
      type: :object,
      anyOf: [
        { "$ref": "#/components/schemas/DeclarationPre2025StartedAttributes" },
        { "$ref": "#/components/schemas/DeclarationPre2025RetainedAttributes" },
        { "$ref": "#/components/schemas/DeclarationPre2025CompletedAttributes" },
        { "$ref": "#/components/schemas/DeclarationPre2025ExtendedAttributes" },
      ],
    },
  },
}.freeze
