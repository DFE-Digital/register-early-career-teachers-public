FactoryBot.define do
  factory :migration_cohort, class: "Migration::Cohort" do
    start_year { Date.current.year - (Date.current.month < 9 ? 1 : 0) }
    registration_start_date { Date.new(start_year.to_i, 6, 1) }
    academic_year_start_date { Date.new(start_year.to_i, 9, 1) }
    automatic_assignment_period_end_date { Date.new(start_year.to_i + 1, 3, 31) }

    initialize_with do
      Migration::Cohort.find_by(start_year:) || new(**attributes)
    end

    trait :with_sequential_start_year do
      sequence(:start_year) { |n| 2021 + (n % 9) }
    end
  end
end
