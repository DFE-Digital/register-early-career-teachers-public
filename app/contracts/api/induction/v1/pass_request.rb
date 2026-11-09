class API::Induction::V1::PassRequest
  include SelfDocumentable::Request

  schema description: "Pass an early career teacher's induction"

  path_param :trn, from: :teacher_trn

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
