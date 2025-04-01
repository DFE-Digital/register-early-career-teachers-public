RSpec.describe 'Uploading ECTs in bulk' do
  include_context 'fake trs api client'

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:file_name) { 'valid_complete' }
  let(:file_path) { Rails.root.join("spec/fixtures/factoried/#{file_name}.csv") }

  include ActiveJob::TestHelper

  before do
    sign_in_as_appropriate_body_user(appropriate_body:)
    page.goto(new_ab_batch_action_path)
  end

  context 'with valid CSV file' do
    scenario 'creates a pending submission for each row' do
      given_i_am_on_the_upload_page
      when_i_upload_a_file

      expect(page.get_by_text('Batch status')).to be_visible
      expect(page.get_by_text('pending')).to be_visible

      perform_enqueued_jobs

      page.reload
      expect(page.get_by_text('completed')).to be_visible
    end
  end

  describe 'bad data' do
    context 'when CSV columns are missing' do
      let(:file_name) { 'invalid_missing_columns' }

      scenario 'fails immediately' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('CSV file contains unsupported columns')
      end
    end

    context 'when a TRN is missing' do
      let(:file_name) { 'invalid_missing_trn' }

      scenario 'fails immediately' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('CSV file contains missing TRNs')
      end
    end

    context 'when a TRN is duplicated' do
      let(:file_name) { 'invalid_duplicate_trns' }

      scenario 'fails immediately' do
        given_i_am_on_the_upload_page
        when_i_upload_a_file
        then_i_should_see_the_error('CSV file contains duplicate TRNs')
      end
    end
  end

private

  def given_i_am_on_the_upload_page
    expect(page.url).to end_with('/appropriate-body/bulk/actions/new')
  end

  def when_i_upload_a_file
    page.locator('input[type="file"]').set_input_files(file_path.to_s)
    page.get_by_role('button', name: "Upload CSV").click
  end

  def then_i_should_see_the_error(error)
    expect(page.url).to end_with('/appropriate-body/bulk/actions')
    expect(page.title).to start_with('Error:')
    expect(page.get_by_text("Error: #{error}")).to be_visible
  end
end
