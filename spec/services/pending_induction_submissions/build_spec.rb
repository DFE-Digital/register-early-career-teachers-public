describe PendingInductionSubmissions::Name do
  subject { PendingInductionSubmissions::Build.new(finished_on:) }

  let(:started_on) { 2.months.ago.to_date }
  let(:finished_on) { 2.weeks.ago.to_date }
  let(:induction_period) { create(:induction_period, started_on:) }

  it { is_expected.to respond_to(:pending_induction_submission) }

  describe '.closing_induction_period' do
    it "sets the started_on date for the pending induction submission to the induction period's start date" do
      pending_induction_period = PendingInductionSubmissions::Build.closing_induction_period(induction_period, finished_on:).pending_induction_submission

      expect(pending_induction_period.started_on).to eql(started_on)
      expect(pending_induction_period.finished_on).to eql(finished_on)
    end
  end
end
