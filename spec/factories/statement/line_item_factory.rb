FactoryBot.define do
  factory(:statement_line_item, class: "Statement::LineItem") do
    statement
    declaration
    status { :eligible }

    ecf_id { SecureRandom.uuid }

    trait :billable do
      status { Statement::LineItem::BILLABLE_STATUS.sample }
    end

    trait :refundable do
      status { Statement::LineItem::REFUNDABLE_STATUS.sample }
    end
  end
end
