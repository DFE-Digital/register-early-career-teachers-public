RSpec.describe AppropriateBodies::ProcessBatch::RecordReleaseJob, type: :job do
  include ActiveJob::TestHelper

  subject(:perform_record_release_job) do
    described_class.perform_now(pending_induction_submission.id, author_email, author_name)
  end

  include_context "test TRS API returns a teacher"

  let(:pending_induction_submission_batch) do
    FactoryBot.create(:pending_induction_submission_batch, :action, appropriate_body_period:)
  end

  let(:pending_induction_submission) do
    FactoryBot.create(:pending_induction_submission,
                      pending_induction_submission_batch:,
                      finished_on: 1.day.ago.to_date,
                      number_of_terms: 10.9)
  end

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:author_email) { "barry@not-a-clue.co.uk" }
  let(:author_name) { "Barry Cryer" }
  let(:teacher) { Teacher.find_by(trn: pending_induction_submission.trn) }
  let(:induction_period) { teacher.induction_periods.first }

  before do
    FactoryBot.create(:teacher, trn: pending_induction_submission.trn)
    FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period:)
  end

  it "closes the induction", :aggregate_failures do
    perform_record_release_job
    perform_enqueued_jobs

    expect(teacher.ongoing_induction_period).to be_nil
    expect(induction_period.finished_on).to eq(pending_induction_submission.finished_on)
    expect(induction_period.number_of_terms).to eq(pending_induction_submission.number_of_terms)
    expect(induction_period.outcome).to be_nil
  end

  it "creates a closed induction event by the author" do
    allow(Events::Record).to receive(:record_induction_period_closed_event!).and_call_original

    perform_record_release_job
    perform_enqueued_jobs

    expect(Events::Record).to have_received(:record_induction_period_closed_event!).with(
      appropriate_body_period:,
      teacher:,
      induction_period:,
      author: an_instance_of(::Events::AppropriateBodyBatchAuthor)
    )
  end
end
