class API::Induction::V1::PassSerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "An appropriate body's pass of an early career teacher's induction."

  schema_field(
    :trn,
    type: :string,
    example: "1234567",
    description: "The teacher reference number."
  )

  schema_field(
    :full_name,
    type: :string,
    example: "John Doe",
    description: "The teacher's name."
  )

  schema_field(
    :passed_on,
    type: :string,
    format: :date,
    example: "2026-07-20",
    description: "The date the ECT passed their induction."
  )

  schema_field(
    :number_of_terms,
    type: :number,
    example: 3,
    description: "The number of terms the ECT completed with you."
  )
end
