RSpec.describe AppropriateBodies::ProcessBatch::RegisterECTJob, type: :job do
  include ActiveJob::TestHelper

  subject(:perform_register_ect_job) do
    described_class.perform_now(pending_induction_submission.id, author_email, author_name)
  end

  include_context "test trs api client"

  let(:pending_induction_submission_batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim, appropriate_body:)
  end

  let(:pending_induction_submission) do
    FactoryBot.create(:pending_induction_submission,
      pending_induction_submission_batch:,
      started_on: 1.week.ago.to_date,
      training_programme: "provider_led")
  end

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:author_email) { "barry@not-a-clue.co.uk" }
  let(:author_name) { "Barry Cryer" }
  let(:teacher) { Teacher.find_by(trn: pending_induction_submission.trn) }
  let(:induction_period) { teacher.induction_periods.first }

  it "records the teacher" do
    expect {
      perform_register_ect_job
      perform_enqueued_jobs
    }.to change(Teacher, :count).by(1)

    expect(teacher.trn).to eq(pending_induction_submission.trn)
    expect(teacher.trs_first_name).to eq(pending_induction_submission.trs_first_name)
    expect(teacher.trs_last_name).to eq(pending_induction_submission.trs_last_name)
  end

  it "opens an induction", :aggregate_failures do
    expect {
      perform_register_ect_job
      perform_enqueued_jobs
    }.to change(InductionPeriod, :count).by(1)

    expect(teacher.ongoing_induction_period).not_to be_nil
    expect(induction_period.started_on).to eq(pending_induction_submission.started_on)
    expect(induction_period.training_programme).to eq(pending_induction_submission.training_programme)
    expect(induction_period.finished_on).to be_nil
    expect(induction_period.outcome).to be_nil
  end

  it "creates an induction opened event by the author" do
    allow(Events::Record).to receive(:record_induction_period_opened_event!).and_call_original

    perform_register_ect_job
    perform_enqueued_jobs

    expect(Events::Record).to have_received(:record_induction_period_opened_event!).with(
      appropriate_body:,
      teacher:,
      induction_period:,
      author: an_instance_of(::Events::AppropriateBodyBatchAuthor),
      modifications: {}
    )
  end

  context "when the teacher was previously registered" do
    before do
      FactoryBot.create(:teacher, trn: pending_induction_submission.trn)
    end

    it "opens a new induction" do
      expect {
        perform_register_ect_job
        perform_enqueued_jobs
      }.to change(InductionPeriod, :count).by(1)
    end

    context "and has an ongoing induction" do
      before do
        FactoryBot.create(:induction_period, :ongoing,
          teacher: Teacher.find_by(trn: pending_induction_submission.trn))
      end

      it "does not create a concurrent induction" do
        expect {
          perform_register_ect_job
          perform_enqueued_jobs
        }.not_to change(InductionPeriod, :count)
      end
    end
  end
end
