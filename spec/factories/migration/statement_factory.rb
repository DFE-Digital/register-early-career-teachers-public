FactoryBot.define do
  factory :migration_statement, class: "Migration::Statement" do
    name          { Time.zone.today.strftime "%B %Y" }
    deadline_date { (Time.zone.today - 1.month).end_of_month }
    payment_date  { Time.zone.today.end_of_month }
    cohort { FactoryBot.create(:migration_cohort) }
    type { "Finance::Statement::ECF" }
    contract_version { "1.0" }
    cpd_lead_provider_id { create(:migration_cpd_lead_provider).id }
  end
end
