class API::Induction::V1::ClaimSerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "An appropriate body's claim on an early career teacher's induction."

  schema_field(
    :trn,
    type: :string,
    example: "1234567",
    description: "The teacher reference number."
  )

  schema_field(
    :full_name,
    type: :string,
    example: "Kirk Van Houten",
    description: "The teacher's name."
  )

  schema_field(
    :started_on,
    type: :string,
    format: :date,
    example: "2026-01-04",
    description: "The date you are claiming the ECT from."
  )

  schema_field(
    :training_programme,
    type: :string,
    enum: TRAINING_PROGRAMME.keys,
    example: "school_led",
    description: "The training programme under which you are registering this claim."
  )
end
