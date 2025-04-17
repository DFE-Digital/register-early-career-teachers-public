FactoryBot.define do
  factory(:pending_induction_submission_batch) do
    association :appropriate_body
    batch_status { 'pending' }
    error_message { nil }
    data { nil }

    trait :claim do
      batch_type { 'claim' }
      csv_file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/valid_complete_claim.csv'), 'text/csv') }
    end

    trait :action do
      batch_type { 'action' }
      csv_file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/valid_complete_action.csv'), 'text/csv') }
    end
  end
end
