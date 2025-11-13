FactoryBot.define do
  factory :migration_milestone, class: "Migration::Milestone" do
    association :schedule, factory: :migration_schedule

    name { "Started" }
    start_date { Date.new(2024, 9, 1) }
    milestone_date { Date.new(2024, 9, 1) }
    payment_date { Date.new(2024, 10, 1) }
    declaration_type { "started" }
  end
end
