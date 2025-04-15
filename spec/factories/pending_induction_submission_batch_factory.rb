FactoryBot.define do
  factory(:pending_induction_submission_batch) do
    association :appropriate_body
    batch_status { 'pending' }
    error_message { nil }
    data { nil }

    trait :action do
      batch_type { 'action' }
      csv_file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/actions/valid_complete.csv'), 'text/csv') }
    end

    trait :claim do
      batch_type { 'claim' }
      csv_file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/claims/valid_complete.csv'), 'text/csv') }
    end
  end
end
