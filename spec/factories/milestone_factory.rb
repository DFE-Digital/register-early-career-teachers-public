FactoryBot.define do
  factory(:milestone) do
    association :schedule

    initialize_with do
      Milestone.find_or_initialize_by(schedule:, declaration_type:)
    end

    declaration_type { "started" }
    start_date { schedule&.contract_period&.started_on }
    milestone_date { 1.month.after(start_date) }

    trait(:started) { declaration_type { "started" } }
    trait(:retained_1) { declaration_type { "retained-1" } }
    trait(:retained_2) { declaration_type { "retained-2" } }
    trait(:retained_3) { declaration_type { "retained-3" } }
    trait(:retained_4) { declaration_type { "retained-4" } }
    trait(:completed) { declaration_type { "completed" } }
  end
end
