FactoryBot.define do
  factory(:statement_clawback_item, class: "Statement::ClawbackItem") do
    statement
    declaration { FactoryBot.create(:statement_payment_item, status: :paid).declaration }
    status { :awaiting_clawback }

    ecf_id { SecureRandom.uuid }
  end
end
