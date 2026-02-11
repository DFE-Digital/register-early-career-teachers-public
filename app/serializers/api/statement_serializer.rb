class API::StatementSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:month) { |s, _| Date::MONTHNAMES[s.month] }
    field(:year) { |s, _| s.year.to_s }
    field(:cohort) { |s, _| s.active_lead_provider.contract_period_year.to_s }
    field :deadline_date, name: :cut_off_date
    field :payment_date
    field(:paid?, name: :paid)
    field :created_at
    field(:api_updated_at, name: :updated_at)
  end

  identifier :api_id, name: :id
  field(:type) { "statement" }

  association :attributes, blueprint: AttributesSerializer do |statement|
    statement
  end
end
