FactoryBot.define do
  factory(:teacher_lead_provider_metadata, class: "Metadata::TeacherLeadProvider") do
    association :teacher
    association :lead_provider
  end
end
