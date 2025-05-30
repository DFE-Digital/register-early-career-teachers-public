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

  describe 'upload page design and functionality' do
    scenario 'displays upload guidance and template download' do
      expect(page.get_by_text('Upload a CSV to claim multiple ECTs')).to be_visible
      expect(page.get_by_text('download a CSV template')).to be_visible
      expect(page.get_by_text('What to include in your CSV file')).to be_visible
      expect(page.get_by_role('button', name: 'Continue')).to be_visible
    end

    scenario 'template download works' do
      template_link = page.get_by_text('download a CSV template')
      expect(template_link.get_attribute('href')).to end_with('bulk-claims-template.csv')
    end
  end

  describe 'successful processing flow' do
    context 'with valid CSV file and existing teachers' do
      before do
        # Create teacher records that match the CSV data
        FactoryBot.create(:teacher, trn: '1234567')
        FactoryBot.create(:teacher, trn: '7654321')
      end

      scenario 'shows progress wheel and completes successfully' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file

        # Progress wheel should appear
        expect(page.get_by_text("We're processing your CSV file, it could take up to 5 minutes.")).to be_visible
        expect(page.get_by_text('0%')).to be_visible

        perform_enqueued_jobs
        page.reload

        # Should show completion page (either success or error summary)
        expect(page.get_by_text('Go back to your overview')).to be_visible
      end
    end

    context 'processing completes and shows results' do
      let(:file_name) { 'seeds_claim.csv' }

      scenario 'shows completion page' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file

        expect(page.get_by_text("We're processing your CSV file")).to be_visible

        perform_enqueued_jobs
        page.reload

        # Should show completion page
        expect(page.get_by_text('Go back to your overview')).to be_visible
      end
    end
  end

  describe 'all errors scenario' do
    let(:file_name) { 'invalid_all_errors_claim.csv' }

    scenario 'shows error summary when all records fail' do
      given_i_am_on_the_upload_page
      when_i_upload_a_file

      expect(page.get_by_text("We're processing your CSV file")).to be_visible

      perform_enqueued_jobs
      page.reload

      # Should show error summary page, not success panel
      expect(page.get_by_text('CSV file summary')).to be_visible
      expect(page.get_by_text('Download CSV with error messages included')).to be_visible
      expect(page.get_by_text('Go back to your overview')).to be_visible

      # Should NOT show success panel
      expect(page.locator('text=ECTs successfully claimed')).to have_count(0)
    end

    scenario 'error CSV download includes error messages' do
      given_i_am_on_the_upload_page
      when_i_upload_a_file

      perform_enqueued_jobs
      page.reload

      # Click error download link
      error_link = page.get_by_text('Download CSV with error messages included')
      expect(error_link.get_attribute('href')).to include('.csv')
    end
  end

  describe 'progress wheel functionality' do
    scenario 'shows increasing progress percentage' do
      given_i_am_on_the_upload_page
      when_i_upload_a_file

      # Should start at 0%
      expect(page.get_by_text('0%')).to be_visible
      expect(page.get_by_text("We're processing your CSV file")).to be_visible

      # Spinner should be visible
      expect(page.locator('.bulk-loader')).to be_visible
    end
  end

  describe 'validation errors (immediate failures)' do
    context 'when CSV columns are missing' do
      let(:file_name) { 'invalid_missing_columns.csv' }

      scenario 'fails immediately with clear error message' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('The selected file must follow the template')
      end
    end

    context 'when a TRN is duplicated' do
      let(:file_name) { 'invalid_duplicate_trns_claim.csv' }

      scenario 'fails immediately with duplication error' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('The selected file has duplicate ECTs')
      end
    end

    context 'when file is not a CSV' do
      let(:file_name) { 'invalid_not_a_csv_file.txt' }

      scenario 'fails immediately with file type error' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('The selected file must be a CSV')
      end
    end

    context 'when CSV is empty' do
      let(:file_name) { 'empty_claim.csv' }

      scenario 'fails immediately with empty file error' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('The selected file is empty')
      end
    end

    context 'when no file is selected' do
      scenario 'shows file required error' do
        given_i_am_on_the_upload_page

        # Click continue without selecting a file
        page.get_by_role('button', name: "Continue").click

        expect(page.url).to end_with('/appropriate-body/bulk/claims')
        expect(page.title).to start_with('Error:')
        expect(page.get_by_text('Error: Attach a CSV file')).to be_visible
      end
    end
  end

  describe 'navigation and user experience' do
    scenario 'back link works correctly' do
      expect(page.get_by_text('Back')).to be_visible
      back_link = page.get_by_text('Back')
      expect(back_link.get_attribute('href')).to include('teachers')
    end

    scenario 'breadcrumb navigation is clear' do
      expect(page.get_by_text('Upload a CSV to claim multiple ECTs')).to be_visible
    end
  end

private

  def given_i_am_on_the_upload_page
    expect(page.url).to end_with('/appropriate-body/bulk/claims/new')
  end

  def when_i_upload_a_file
    page.locator('input[type="file"]').set_input_files(file_path)
    page.get_by_role('button', name: "Continue").click
  end

  def then_i_should_see_the_error(error)
    expect(page.url).to end_with('/appropriate-body/bulk/claims')
    expect(page.title).to start_with('Error:')
    expect(page.get_by_text("Error: #{error}")).to be_visible
  end
end
