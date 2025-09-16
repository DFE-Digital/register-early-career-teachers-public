FactoryBot.define do
  factory(:milestone) do
    association :schedule
    declaration_type { 'started' }

    start_date { Date.new(2024, 9, 1) }
    milestone_date { Date.new(2024, 9, 1) }
  end
end
