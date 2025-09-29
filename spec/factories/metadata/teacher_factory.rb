FactoryBot.define do
  factory(:teacher_metadata, class: "Metadata::Teacher") do
    after(:build) do |metadata|
      metadata.teacher ||= DeclarativeUpdates.skip(:metadata) { FactoryBot.create(:teacher) }
    end

    first_became_eligible_for_ect_training_at { nil }
    first_became_eligible_for_mentor_training_at { nil }
  end
end
