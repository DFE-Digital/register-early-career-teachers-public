class API::Induction::V1::InductionPeriodSerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "An induction period."

  schema_field :trn,
               type: :string,
               description: "The teacher's TRN.",
               example: "1234567"

  schema_field :full_name,
               type: :string,
               description: "The teacher's full name.",
               example: "John Keating"

  schema_field :status,
               type: :string,
               enum: %w[ongoing pass fail release],
               description: "The status of the induction period.",
               example: "ongoing"

  schema_field :started_on,
               type: :string,
               format: :date,
               description: "The date the induction period started.",
               example: "2025-09-01"

  schema_field :finished_on,
               type: :string,
               format: :date,
               nullable: true,
               description: "The date the induction period finished.",
               example: "2026-07-20"

  schema_field :training_programme,
               type: :string,
               enum: %w[provider_led school_led],
               nullable: true,
               description: "The training programme.",
               example: "provider_led"

  schema_field :number_of_terms,
               type: :number,
               nullable: true,
               description: "The number of terms completed.",
               example: 3
end
