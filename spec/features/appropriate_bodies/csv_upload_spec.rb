RSpec.describe 'Uploading ECTs in bulk' do
  include_context 'fake trs api client'

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:file_name) { 'valid_complete' }
  let(:file_path) { Rails.root.join("spec/fixtures/factoried/#{file_name}.csv") }

  include ActiveJob::TestHelper

  before { sign_in_as_appropriate_body_user(appropriate_body:) }

  context "with valid CSV file" do
    scenario 'happy path' do
      page.goto(new_ab_import_path)
      expect(page.url).to end_with('/appropriate-body/imports/new')

      page.locator('input[type="file"]').set_input_files(file_path.to_s)
      page.get_by_role('button', name: "Upload CSV").click

      expect(page.get_by_text('Batch status')).to be_visible
      expect(page.get_by_text('pending')).to be_visible

      batch = PendingInductionSubmissionBatch.find_by(appropriate_body:)

      expect(batch.pending_induction_submissions.count).to eq 0

      perform_enqueued_jobs

      expect(batch.pending_induction_submissions.count).to eq 14

      page.reload
      expect(page.get_by_text('completed')).to be_visible
    end
  end
end
