RSpec.describe AppropriateBodies::ProcessBatch::RecordPassJob, type: :job do
  include ActiveJob::TestHelper

  subject(:perform_record_pass_job) do
    described_class.perform_now(pending_induction_submission.id, author_email, author_name)
  end

  include_context "test TRS API returns a teacher"

  let(:pending_induction_submission_batch) do
    FactoryBot.create(:pending_induction_submission_batch, :action, appropriate_body_period:)
  end

  let(:pending_induction_submission) do
    FactoryBot.create(:pending_induction_submission,
                      pending_induction_submission_batch:,
                      finished_on: 1.week.ago.to_date,
                      number_of_terms: 3.2,
                      outcome: "pass")
  end

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:author_email) { "barry@not-a-clue.co.uk" }
  let(:author_name) { "Barry Cryer" }
  let(:teacher) { pending_induction_submission.teacher }
  let(:induction_period) { teacher.induction_periods.first }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: induction_period.started_on) }

  before do
    FactoryBot.create(:teacher, trn: pending_induction_submission.trn)
    FactoryBot.create(:induction_period, :unfinished, teacher: pending_induction_submission.teacher, appropriate_body_period:)
  end

  it "records an outcome for the induction", :aggregate_failures do
    perform_record_pass_job
    perform_enqueued_jobs

    expect(teacher.ongoing_induction_period).to be_nil
    expect(induction_period.finished_on).to eq(pending_induction_submission.finished_on)
    expect(induction_period.outcome).to eq(pending_induction_submission.outcome)
    expect(induction_period.number_of_terms).to eq(pending_induction_submission.number_of_terms)
  end

  it "creates a pass induction event by the author" do
    expected_ect_at_school_period_id = ect_at_school_period.id

    perform_record_pass_job

    expect(Event.where(event_type: "teacher_passes_induction").sole).to have_attributes(
      appropriate_body_period_id: appropriate_body_period.id,
      teacher_id: teacher.id,
      induction_period_id: induction_period.id,
      ect_at_school_period_id: expected_ect_at_school_period_id,
      mentorship_period_id: nil,
      training_period_id: nil
    )
  end
end
