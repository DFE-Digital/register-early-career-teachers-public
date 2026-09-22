FactoryBot.define do
  factory(:teaching_school_hub) do
    initialize_with do
      TeachingSchoolHub.find_or_initialize_by(name:)
    end

    sequence(:name) { |n| "Teaching School Hub #{n}" }
  end
end
