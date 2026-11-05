INDUCTION_PASS_REQUEST = {
  description: "Pass an early career teacher's induction",
  type: :object,
  required: %w[passed_on number_of_terms],
  properties: {
    passed_on: {
      description: "The date the ECT passed their induction.",
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
