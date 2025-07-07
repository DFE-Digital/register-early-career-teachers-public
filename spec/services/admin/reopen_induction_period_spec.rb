RSpec.describe Admin::ReopenInductionPeriod do
  subject(:service) { described_class.new(author:, induction_period:) }

  let(:admin) { create(:user, email: 'admin-user@education.gov.uk') }
  let(:author) { Sessions::Users::DfEPersona.new(email: admin.email) }
  let(:teacher) { create(:teacher) }
  let(:outcome) { nil }
  let(:number_of_terms) { 4.5 }
  let(:finished_on) { "2023-12-31" }

  let(:induction_period) do
    create(
      :induction_period,
      teacher:,
      outcome:,
      number_of_terms:,
      started_on: "2023-06-01",
      finished_on:
    )
  end

  describe "#reopen_induction_period!" do
    it "reopens the induction period" do
      expect {
        service.reopen_induction_period!
      }.to change { induction_period.reload.finished_on }.to(nil)
        .and change { induction_period.reload.number_of_terms }.to(nil)
    end

    it "adds an event" do
      induction_period.finished_on = induction_period.number_of_terms = nil
      modifications = induction_period.changes
      appropriate_body = induction_period.appropriate_body
      induction_period.reload

      expect(Events::Record).to receive(:record_induction_period_reopened_event!)
        .with(author:, induction_period:, modifications:, teacher:, appropriate_body:)

      service.reopen_induction_period!
    end

    context "when induction period has an outcome" do
      let(:outcome) { "pass" }

      it "removes the outcome" do
        expect { service.reopen_induction_period! }.to change { induction_period.reload.outcome }.to(nil)
      end

      it "queues a job that updates the TRS status" do
        expect {
          service.reopen_induction_period!
        }.to have_enqueued_job(ReopenInductionJob).with(trn: teacher.trn, start_date: induction_period.started_on)
      end
    end

    context "when the last induction period is ongoing" do
      let(:number_of_terms) { nil }
      let(:finished_on) { nil }

      it "raises an error" do
        expect {
          service.reopen_induction_period!
        }.to raise_error(Admin::ReopenInductionPeriod::ReopenInductionError)
      end
    end

    context "when the induction period is not the last" do
      let!(:newer_period) do
        create(
          :induction_period,
          teacher:,
          outcome:,
          number_of_terms: 2,
          started_on: "2024-01-01",
          finished_on: "2024-06-30"
        )
      end

      it "raises an error" do
        expect {
          service.reopen_induction_period!
        }.to raise_error(Admin::ReopenInductionPeriod::ReopenInductionError)
      end
    end
  end
end
