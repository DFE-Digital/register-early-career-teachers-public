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

      perform_enqueued_jobs
      page.reload
      expect(page.get_by_text('CSV file summary')).to be_visible
      expect(page.get_by_text("Your CSV named 'valid_complete_claim.csv' has 2 ECTs")).to be_visible
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
      let(:file_name) { 'invalid_duplicate_trns_claim.csv' }

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

    context 'when uploading corrected file after invalid file upload' do
      let(:file_name) { 'invalid_missing_columns.csv' }
      let(:corrected_file_name) { 'valid_complete_claim.csv' }
      let(:corrected_file_path) { Rails.root.join("spec/fixtures/#{corrected_file_name}").to_s }

      scenario 'should allow uploading the corrected file' do
        # First upload fails as expected
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('The selected file must follow the template')

        # Now try to upload a corrected file
        when_i_upload_a_file(corrected_file_path)

        perform_enqueued_jobs
        page.reload
        expect(page.get_by_text('CSV file summary')).to be_visible
        expect(page.get_by_text("Your CSV named 'valid_complete_claim.csv' has 2 ECTs")).to be_visible
      end
    end
  end

private

  def given_i_am_on_the_upload_page
    expect(page.url).to end_with('/appropriate-body/bulk/claims/new')
  end

  def when_i_upload_a_file(input_file = file_path)
    page.locator('input[type="file"]').set_input_files(input_file)
    page.get_by_role('button', name: "Continue").click
  end

  def then_i_should_see_the_error(error)
    expect(page.url).to end_with('/appropriate-body/bulk/claims')
    expect(page.title).to start_with('Error:')
    expect(page.get_by_text("Error: #{error}")).to be_visible
  end
end
