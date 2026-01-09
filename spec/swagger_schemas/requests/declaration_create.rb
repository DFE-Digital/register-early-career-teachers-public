DECLARATION_CREATE_REQUEST = {
  description: "A participant declaration request",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      type: :object,
      anyOf: [
        { "$ref": "#/components/schemas/DeclarationPre2025DataRequest" },
        { "$ref": "#/components/schemas/DeclarationPost2024ECTDataRequest" },
        { "$ref": "#/components/schemas/DeclarationPost2024MentorDataRequest" },
      ],
    },
  },
  example: {
    data: {
      type: "participant-declaration",
      attributes: {
        participant_id: "3452b1a6-cbaa-422f-9ca9-40afa28583a2",
        declaration_type: "retained-1",
        declaration_date: "2021-05-31T02:21:32.000Z",
        course_identifier: "ecf-induction",
        evidence_held: "training-event-attended",
      },
    },
  },
}.freeze
