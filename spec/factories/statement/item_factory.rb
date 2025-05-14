FactoryBot.define do
  factory(:statement_item, class: "Statement::Item") do
    association :statement

    trait :eligible do
      state { :eligible }
    end

    trait :ineligible do
      state { :ineligible }
    end

    trait :voided do
      state { :voided }
    end

    trait :payable do
      state { :payable }
    end

    trait :paid do
      state { :paid }
    end

    trait :awaiting_clawback do
      state { :awaiting_clawback }
    end

    trait :clawed_back do
      state { :clawed_back }
    end

    trait :voided do
      state { :voided }
    end
  end
end
