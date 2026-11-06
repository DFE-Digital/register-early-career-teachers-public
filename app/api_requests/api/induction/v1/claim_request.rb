class API::Induction::V1::ClaimRequest
  include SelfDocumentable::Request

  schema description: "Claim an early career teacher's induction"

  path_param :trn, from: :teacher_trn

  schema_field(
    :date_of_birth,
    type: :string,
    format: :date,
    example: "2001-05-13",
    description: "The teacher's date of birth."
  )

  schema_field(
    :claimed_from,
    type: :string,
    format: :date,
    example: "2026-01-04",
    description: "The date you are claiming the ECT from."
  )

  schema_field(
    :training_programme,
    type: :string,
    enum: TRAINING_PROGRAMME.keys,
    example: TRAINING_PROGRAMME.keys.first,
    description: "The training programme under which you are registering this claim."
  )
end
