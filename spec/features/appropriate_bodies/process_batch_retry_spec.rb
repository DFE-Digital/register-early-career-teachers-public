RSpec.describe 'Process bulk claims then actions which have become invalidated' do
  include ActiveJob::TestHelper

  include_context 'test trs api client'

  let(:appropriate_body) do
    FactoryBot.create(:appropriate_body, name: 'The Appropriate Body')
  end

  before do
    sign_in_as_appropriate_body_user(appropriate_body:)
  end

  scenario 'redo processing' do
    page.goto(new_ab_batch_claim_path)
    expect(page.url).to end_with('/appropriate-body/bulk/claims/new')
    when_i_upload_a_file('valid_complete_claim.csv')

    expect(PendingInductionSubmissionBatch.last).to be_pending
    expect(perform_enqueued_jobs).to be(2)
    expect(PendingInductionSubmissionBatch.last).to be_processed
    expect(Event.all.map(&:heading)).to eq(["The Appropriate Body started a bulk claim"])

    page.reload
    expect(page.get_by_text('CSV file summary')).to be_visible
    expect(page.get_by_text("Your CSV named 'valid_complete_claim.csv' has 2 ECT records that you can claim.")).to be_visible
    page.get_by_role('button', name: 'Claim ECTs').click

    expect(perform_enqueued_jobs).to be(2)
    expect(PendingInductionSubmissionBatch.last).to be_completed
    expect(perform_enqueued_jobs).to be(8)

    page.reload
    expect(page.get_by_text("You claimed 2 ECT records.")).to be_visible
    page.get_by_role('link', name: 'Go back to your overview').click
    expect(page.get_by_text('valid_complete_claim.csv')).to be_visible

    page.goto(new_ab_batch_action_path)
    expect(page.url).to end_with('/appropriate-body/bulk/actions/new')
    when_i_upload_a_file('valid_complete_action.csv')

    expect(PendingInductionSubmissionBatch.last).to be_pending
    expect(perform_enqueued_jobs).to be(2)
    expect(PendingInductionSubmissionBatch.last).to be_processed

    page.reload
    expect(page.get_by_text('CSV file summary')).to be_visible
    expect(page.get_by_text("Your CSV named 'valid_complete_action.csv' has 2 ECT records")).to be_visible
    expect(page.get_by_text("1 ECT with a passed induction")).to be_visible
    expect(page.get_by_text("1 ECT with a failed induction")).to be_visible
    expect(page.get_by_text("0 ECTs with a released outcome")).to be_visible

    expect(PendingInductionSubmissionBatch.last.pending_induction_submissions.map(&:error_messages)).to contain_exactly([], [])

    # Delete the induction we wanted to fail and invalidate the row
    Teacher.find_by(trn: '7654321').induction_periods.delete_all

    page.get_by_role('button', name: 'Record outcomes').click
    expect(perform_enqueued_jobs).to be(2)
    expect(PendingInductionSubmissionBatch.last).to be_processed # rechecked
    expect(PendingInductionSubmissionBatch.last.pending_induction_submissions.map(&:error_messages)).to contain_exactly(
      [],
      [/does not have an open induction/]
    )

    page.reload
    # Updated expectation
    expect(page.get_by_text('CSV file summary')).to be_visible
    expect(page.get_by_text("Your CSV named 'valid_complete_action.csv' has 1 ECT record")).to be_visible
    expect(page.get_by_text("1 ECT with a passed induction")).to be_visible
    expect(page.get_by_text("0 ECTs with a failed induction")).to be_visible
    expect(page.get_by_text("0 ECTs with a released outcome")).to be_visible
    expect(page.get_by_text("You had 1 ECT with errors")).to be_visible
  end

private

  def when_i_upload_a_file(file_name)
    file_path = Rails.root.join("spec/fixtures/#{file_name}").to_s
    page.locator('input[type="file"]').set_input_files(file_path)
    page.get_by_role('button', name: 'Continue').click
  end
end
