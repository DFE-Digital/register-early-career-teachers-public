FactoryBot.define do
  factory(:statement_payment_item, class: "Statement::PaymentItem") do
    statement
    declaration
    status { :eligible }

    ecf_id { SecureRandom.uuid }
  end
end
