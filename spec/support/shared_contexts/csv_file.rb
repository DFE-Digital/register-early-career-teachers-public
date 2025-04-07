RSpec.shared_context 'csv file' do |name, type|
  include Rack::Test::Methods

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:csv_file) do
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/#{type.pluralize}/#{name}.csv"), 'text/csv')
  end

  let(:pending_induction_submission_batch) do
    FactoryBot.create(:pending_induction_submission_batch, type.to_sym,
                      csv_file:,
                      appropriate_body:)
  end
end
