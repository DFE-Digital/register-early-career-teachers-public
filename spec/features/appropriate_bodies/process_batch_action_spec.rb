RSpec.describe 'Process bulk actions' do
  include_context 'fake trs api client'

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:file_name) { 'valid_complete_action.csv' }
  let(:file_path) { Rails.root.join("spec/fixtures/#{file_name}").to_s }

  include ActiveJob::TestHelper

  before do
    sign_in_as_appropriate_body_user(appropriate_body:)
    page.goto(new_ab_batch_action_path)
  end

  context 'when batch is owned by another appropriate body' do
    let(:other_appropriate_body) { FactoryBot.create(:appropriate_body) }
    let(:batch) { FactoryBot.create(:pending_induction_submission_batch, :claim, appropriate_body: other_appropriate_body) }

    before { page.goto(ab_batch_claim_path(batch.id)) }

    scenario 'renders error message' do
      expect(page.title).to start_with('You are not authorised to access this page')
      expect(page.get_by_text('You are not authorised to access this page')).to be_visible
    end
  end

  context 'with valid CSV file' do
    scenario 'creates a pending submission for each row' do
      given_i_am_on_the_upload_page
      when_i_upload_a_file
      then_i_should_see_the_status('pending')

      # This job does validation first, leaving the user to confirm with a CTA
      perform_enqueued_jobs
      page.reload

      then_i_should_see_the_status('processed')
    end
  end

  describe 'bad data' do
    context 'when CSV columns are missing' do
      let(:file_name) { 'invalid_missing_columns.csv' }

      scenario 'fails immediately' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('The selected file must follow the template')
      end
    end

    context 'when a TRN is duplicated' do
      let(:file_name) { 'invalid_duplicate_trns_action.csv' }

      scenario 'fails immediately' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('The selected file has duplicate ECTs')
      end
    end

    context 'when file is not a CSV' do
      let(:file_name) { 'invalid_not_a_csv_file.txt' }

      scenario 'fails immediately' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('The selected file must be a CSV')
      end
    end
  end

private

  def given_i_am_on_the_upload_page
    expect(page.url).to end_with('/appropriate-body/bulk/actions/new')
  end

  def when_i_upload_a_file
    page.locator('input[type="file"]').set_input_files(file_path)
    page.get_by_role('button', name: "Upload action CSV").click
  end

  def then_i_should_see_the_error(error)
    expect(page.url).to end_with('/appropriate-body/bulk/actions')
    expect(page.title).to start_with('Error:')
    expect(page.get_by_text("Error: #{error}")).to be_visible
  end

  def then_i_should_see_the_status(status)
    expect(page.get_by_text('Batch status')).to be_visible
    expect(page.get_by_text(status, exact: true)).to be_visible
  end
end
