FactoryBot.define do
  factory(:schedule) do
    association :contract_period
    identifier { "ecf-standard-september" }

    initialize_with do
      Schedule.find_or_create_by(contract_period:, identifier:)
    end

    trait :replacement_schedule do
      identifier { "ecf-replacement-september" }
    end

    trait :with_milestones do
      after(:build) do |schedule|
        year = schedule.contract_period.year

        milestone_data = [
          { declaration_type: "started",    start_date: Date.new(year, 6, 1),     milestone_date: Date.new(year, 12, 31) },
          { declaration_type: "retained-1", start_date: Date.new(year + 1, 1, 1), milestone_date: Date.new(year + 1, 3, 31) },
          { declaration_type: "retained-2", start_date: Date.new(year + 1, 4, 1), milestone_date: Date.new(year + 1, 7, 31) },
          { declaration_type: "retained-3", start_date: Date.new(year + 1, 8, 1), milestone_date: Date.new(year + 1, 12, 31) },
          { declaration_type: "retained-4", start_date: Date.new(year + 2, 1, 1), milestone_date: Date.new(year + 2, 3, 31) },
          { declaration_type: "completed",  start_date: Date.new(year + 2, 4, 1), milestone_date: Date.new(year + 2, 7, 31) }
        ]

        milestone_data.each do |attrs|
          declaration_type = attrs[:declaration_type]
          milestone = create(:milestone, schedule:, declaration_type:)
          milestone.update!(
            start_date: attrs[:start_date],
            milestone_date: attrs[:milestone_date]
          )
        end
      end
    end
  end
end
