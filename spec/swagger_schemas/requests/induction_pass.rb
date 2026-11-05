INDUCTION_PASS_REQUEST = {
  description: "Pass an early career teacher's induction",
  type: :object,
  required: %w[completed_on number_of_terms],
  properties: {
    completed_on: {
      description: "The date the ECT completed their induction.",
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
