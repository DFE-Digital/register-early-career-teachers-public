RSpec.describe 'Process bulk claims then actions events' do
  include ActiveJob::TestHelper

  include_context 'fake trs api returns a teacher and then a teacher that is exempt from induction'

  let(:appropriate_body) do
    FactoryBot.create(:appropriate_body, name: 'The Appropriate Body')
  end

  before do
    sign_in_as_appropriate_body_user(appropriate_body:)
  end

  scenario 'happy path' do
    # action
    page.goto(new_ab_batch_claim_path)
    expect(page.url).to end_with('/appropriate-body/bulk/claims/new')
    when_i_upload_a_file('valid_complete_claim.csv')

    expect(PendingInductionSubmissionBatch.last).to be_pending
    expect(perform_enqueued_jobs).to be(2) # processing
    expect(PendingInductionSubmissionBatch.last).to be_processed
    expect(Event.all.map(&:heading)).to eq([
      "The Appropriate Body started a bulk claim"
    ])

    page.reload
    expect(page.get_by_text('CSV file summary')).to be_visible
    expect(page.get_by_text("Your CSV named 'valid_complete_claim.csv' has 2 ECT records that you can claim.")).to be_visible
    page.get_by_role('button', name: 'Claim ECTs').click

    expect(perform_enqueued_jobs).to be(2) # completing
    expect(PendingInductionSubmissionBatch.last).to be_completed
    expect(Event.all.map(&:heading)).to eq([
      "The Appropriate Body started a bulk claim",
      "The Appropriate Body completed a bulk claim"
    ])
    expect(perform_enqueued_jobs).to be(8)
    expect(Event.all.map(&:heading)).to eq([
      "The Appropriate Body started a bulk claim",
      "The Appropriate Body completed a bulk claim",
      "Imported from TRS",
      "Induction status changed from '' to 'InProgress'",
      "Kirk Van Houten was claimed by The Appropriate Body",
      "Imported from TRS",
      "Induction status changed from '' to 'InProgress'",
      "Kirk Van Houten was claimed by The Appropriate Body"
    ])

    page.reload
    expect(page.get_by_text("You claimed 2 ECT records.")).to be_visible
    page.get_by_role('link', name: 'Go back to your overview').click
    expect(page.get_by_text('valid_complete_claim.csv')).to be_visible

    # claim
    page.goto(new_ab_batch_action_path)
    expect(page.url).to end_with('/appropriate-body/bulk/actions/new')
    when_i_upload_a_file('valid_complete_action.csv')

    expect(PendingInductionSubmissionBatch.last).to be_pending
    expect(perform_enqueued_jobs).to be(2) # processing
    expect(PendingInductionSubmissionBatch.last).to be_processed
    expect(Event.all.map(&:heading)).to eq([
      "The Appropriate Body started a bulk claim",
      "The Appropriate Body completed a bulk claim",
      "Imported from TRS",
      "Induction status changed from '' to 'InProgress'",
      "Kirk Van Houten was claimed by The Appropriate Body",
      "Imported from TRS",
      "Induction status changed from '' to 'InProgress'",
      "Kirk Van Houten was claimed by The Appropriate Body",
      "The Appropriate Body started a bulk action"
    ])

    page.reload
    # Processed
    expect(page.get_by_text('CSV file summary')).to be_visible
    expect(page.get_by_text("Your CSV named 'valid_complete_action.csv' has 2 ECT records")).to be_visible
    expect(page.get_by_text("1 ECT with a passed induction")).to be_visible
    expect(page.get_by_text("1 ECT with a failed induction")).to be_visible
    expect(page.get_by_text("0 ECTs with a released outcome")).to be_visible
    page.get_by_role('button', name: 'Record outcomes').click

    expect(perform_enqueued_jobs).to be(2) # completing
    expect(PendingInductionSubmissionBatch.last).to be_completed
    expect(Event.all.map(&:heading)).to eq([
      "The Appropriate Body started a bulk claim",
      "The Appropriate Body completed a bulk claim",
      "Imported from TRS",
      "Induction status changed from '' to 'InProgress'",
      "Kirk Van Houten was claimed by The Appropriate Body",
      "Imported from TRS",
      "Induction status changed from '' to 'InProgress'",
      "Kirk Van Houten was claimed by The Appropriate Body",
      "The Appropriate Body started a bulk action",
      "The Appropriate Body completed a bulk action"
    ])

    expect(perform_enqueued_jobs).to be(4)
    expect(Event.all.map(&:heading)).to eq([
      "The Appropriate Body started a bulk claim",
      "The Appropriate Body completed a bulk claim",
      "Imported from TRS",
      "Induction status changed from '' to 'InProgress'",
      "Kirk Van Houten was claimed by The Appropriate Body",
      "Imported from TRS",
      "Induction status changed from '' to 'InProgress'",
      "Kirk Van Houten was claimed by The Appropriate Body",
      "The Appropriate Body started a bulk action",
      "The Appropriate Body completed a bulk action",
      "Kirk Van Houten passed induction",
      "Kirk Van Houten failed induction"
    ])

    # Mimic PurgePendingInductionSubmissionsJob
    PendingInductionSubmission.ready_for_deletion.delete_all

    page.reload
    # Completed
    expect(page.get_by_text("You uploaded 2 ECT records including:")).to be_visible
    expect(page.get_by_text("1 ECT with a passed induction")).to be_visible
    expect(page.get_by_text("1 ECT with a failed induction")).to be_visible
    expect(page.get_by_text("0 ECTs with a released outcome")).to be_visible
    page.get_by_role('link', name: 'Go back to your overview').click
    expect(page.get_by_text('valid_complete_action.csv')).to be_visible

    # All events link to the batch and appropriate body
    Event.all.map do |event|
      expect(event.pending_induction_submission_batch.appropriate_body.id).to eq(appropriate_body.id)
    end
  end

private

  def when_i_upload_a_file(file_name)
    file_path = Rails.root.join("spec/fixtures/#{file_name}").to_s
    page.locator('input[type="file"]').set_input_files(file_path)
    page.get_by_role('button', name: 'Continue').click
  end
end
