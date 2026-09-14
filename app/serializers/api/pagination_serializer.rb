class API::PaginationSerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "Pagination information for API responses."

  schema_field :page,
               type: :integer,
               description: "The current page number.",
               example: 1

  schema_field :per_page,
               type: :integer,
               description: "The number of items per page.",
               example: 20
end
