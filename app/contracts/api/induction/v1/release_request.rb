class API::Induction::V1::ReleaseRequest
  include SelfDocumentable::Request

  schema description: "Release an early career teacher"

  path_param :trn, from: :teacher_trn

  schema_field(
    :released_on,
    type: :string,
    format: :date,
    example: "2026-07-20",
    description: "The date the ECT was released."
  )

  schema_field(
    :number_of_terms,
    type: :number,
    example: 3,
    description: "The number of terms the ECT completed with you."
  )
end
