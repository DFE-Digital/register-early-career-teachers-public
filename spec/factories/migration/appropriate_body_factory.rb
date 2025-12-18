FactoryBot.define do
  factory :migration_appropriate_body, class: "Migration::AppropriateBody" do
    sequence(:name) { |n| "Migration Appropriate Body #{n}" }
    body_type { "teaching_school_hub" }
  end
end
