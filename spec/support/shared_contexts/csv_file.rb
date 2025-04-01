RSpec.shared_context 'csv file' do |name|
  include Rack::Test::Methods

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:csv_file) do
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/factoried/#{name}.csv"), 'text/csv')
  end

  let(:pending_induction_submission_batch) do
    PendingInductionSubmissionBatch.new(appropriate_body:, csv_file:)
  end
end
