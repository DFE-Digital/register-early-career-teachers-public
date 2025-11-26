FactoryBot.define do
  factory(:statement_line_item, class: "Statement::LineItem") do
    statement
    declaration
    status { :eligible }

    ecf_id { SecureRandom.uuid }
  end
end
