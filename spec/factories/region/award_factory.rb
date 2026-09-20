FactoryBot.define do
  factory(:region_award, class: "Region::Award") do
    appropriate_body_period { association :appropriate_body_period, :teaching_school_hub }
    school { association :school }
    region { association :region }

    deactivated_at { nil }

    trait :deactivated do
      deactivated_at { 1.day.ago }
    end
  end
end
