INDUCTION_CLAIM_REQUEST = {
  description: "Claim an early career teacher's induction",
  type: :object,
  required: %w[date_of_birth claimed_from training_programme],
  properties: {
    date_of_birth: {
      description: "The teacher's date of birth.",
      type: :string,
      format: :date,
      example: "2001-05-13",
    },
    claimed_from: {
      description: "The date you are claiming the ECT from.",
      type: :string,
      format: :date,
      example: "2026-01-04",
    },
    training_programme: {
      description: "The training programme under which you are registering this claim.",
      type: :string,
      enum: TRAINING_PROGRAMME.keys,
      example: TRAINING_PROGRAMME.keys.first,
    },
  },
}.freeze
