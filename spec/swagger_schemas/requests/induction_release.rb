INDUCTION_RELEASE_REQUEST = {
  description: "Release an early career teacher",
  type: :object,
  required: %w[released_on number_of_terms],
  properties: {
    released_on: {
      description: "The date the ECT was released.",
      type: :string,
      format: :date,
      example: "2026-07-20",
    },
    number_of_terms: {
      description: "The number of terms the ECT completed with you.",
      type: :number,
      example: 3,
    },
  },
}.freeze
