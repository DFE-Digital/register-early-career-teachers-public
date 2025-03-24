RSpec.describe 'Uploading ECTs in bulk' do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:file_path) { Rails.root.join('spec/fixtures/seeds.csv').to_s }

  include ActiveJob::TestHelper

  before { sign_in_as_appropriate_body_user(appropriate_body:) }

  context "with valid CSV file" do
    # TODO: spec/support/shared_contexts/fake_trs_api_client.rb
    # include_context 'fake trs api client that finds teacher with specific induction status', 'xxx'

    scenario 'happy path' do
      page.goto(new_ab_import_path)
      expect(page.url).to end_with('/appropriate-body/imports/new')

      page.locator('input[type="file"]').set_input_files(file_path)
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
