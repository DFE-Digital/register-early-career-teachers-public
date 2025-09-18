FactoryBot.define do
  factory(:teacher_metadata, class: "Metadata::Teacher") do
    after(:build) do |metadata|
      metadata.teacher ||= Metadata::Manager.skip_metadata_updates { FactoryBot.create(:teacher) }
    end

    induction_started_on { Faker::Time.between(from: 1.year.ago, to: 2.months.ago) }
    induction_finished_on { Faker::Time.between(from: 2.months.ago, to: 1.day.ago) }
    updated_at { Faker::Time.between(from: 1.month.ago, to: Time.zone.now) }
  end
end
