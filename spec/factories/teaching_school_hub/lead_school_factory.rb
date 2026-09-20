FactoryBot.define do
  factory(:teaching_school_hub_lead_school, class: "TeachingSchoolHub::LeadSchool") do
    appropriate_body { association :appropriate_body_period, :teaching_school_hub }
    school { association :school }
    region { association :region }

    deactivated_at { nil }

    trait :deactivated do
      deactivated_at { 1.day.ago }
    end
  end
end
