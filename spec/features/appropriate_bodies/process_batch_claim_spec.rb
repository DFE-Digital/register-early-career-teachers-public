RSpec.describe 'Process bulk claims' do
  include_context 'fake trs api client'

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:file_name) { 'valid_complete_claim.csv' }
  let(:file_path) { Rails.root.join("spec/fixtures/#{file_name}").to_s }

  include ActiveJob::TestHelper

  before do
    sign_in_as_appropriate_body_user(appropriate_body:)
    page.goto(new_ab_batch_claim_path)
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

      expect(page.get_by_text('Batch status')).to be_visible
      expect(page.get_by_text('pending')).to be_visible

      perform_enqueued_jobs
      # This job does validation and persistence of the claims all at once
      page.reload
      expect(page.get_by_text('completed', exact: true)).to be_visible
    end
  end

  describe 'bad data' do
    context 'when CSV has too many rows', pending: 'alternative to fixtures' do
      let(:file_name) { 'invalid_too_many_rows.csv' }

      scenario 'fails immediately' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('CSV file contains too many rows')
      end
    end

    context 'when CSV file is too large', pending: 'alternative to fixtures' do
      let(:file_name) { 'invalid_too_large.csv' }

      scenario 'fails immediately' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('File size must be less than 1MB')
      end
    end

    context 'when CSV columns are missing' do
      let(:file_name) { 'invalid_missing_columns.csv' }

      scenario 'fails immediately' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('CSV file contains unsupported columns')
      end
    end

    context 'when a TRN is duplicated' do
      let(:file_name) { 'invalid_duplicate_trns_claim.csv' }

      scenario 'fails immediately' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('CSV file contains duplicate TRNs')
      end
    end

    context 'when file is not a CSV' do
      let(:file_name) { 'invalid_not_a_csv_file.txt' }

      scenario 'fails immediately' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('File type must be a CSV')
      end
    end
  end

private

  def given_i_am_on_the_upload_page
    expect(page.url).to end_with('/appropriate-body/bulk/claims/new')
  end

  def when_i_upload_a_file
    page.locator('input[type="file"]').set_input_files(file_path)
    page.get_by_role('button', name: "Upload claim CSV").click
  end

  def then_i_should_see_the_error(error)
    expect(page.url).to end_with('/appropriate-body/bulk/claims')
    expect(page.title).to start_with('Error:')
    expect(page.get_by_text("Error: #{error}")).to be_visible
  end
end
