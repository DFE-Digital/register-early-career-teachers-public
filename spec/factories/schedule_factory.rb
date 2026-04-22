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

    trait :extended_september do
      identifier { "ecf-extended-september" }
    end

    trait :with_milestones do
      after(:build) do |schedule|
        year = schedule.contract_period.year
        _, type, period = schedule.identifier.split("-")

        start_date =
          case period
          when "september"
            type == "standard" ? Date.new(year, 6, 1) : Date.new(year, 9, 1)
          when "january"
            Date.new(year + 1, 1, 1)
          when "april"
            Date.new(year + 1, 4, 1)
          end

        %w[started retained-1 retained-2 retained-3 retained-4 completed extended-1 extended-2 extended-3].each do |declaration_type|
          next if schedule.milestones.exists?(declaration_type:)

          milestone = create(:milestone, schedule:, declaration_type:)
          milestone.update!(start_date:, milestone_date: nil)
        end
      end
    end
  end
end
