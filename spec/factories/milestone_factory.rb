FactoryBot.define do
  factory(:milestone) do
    association :schedule

    initialize_with do
      Milestone.find_or_initialize_by(schedule:, declaration_type:)
    end

    declaration_type { "started" }
    start_date { schedule&.contract_period&.started_on }
    milestone_date { 1.month.after(start_date) }
  end
end
