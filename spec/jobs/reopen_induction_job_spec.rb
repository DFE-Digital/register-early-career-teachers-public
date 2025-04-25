RSpec.describe ReopenInductionJob, type: :job do
  describe "#perform" do
    let(:trn) { "1234567" }
    let(:start_date) { 1.year.ago }
    let(:trs_client) { instance_double(TRS::APIClient) }

    before do
      allow(TRS::APIClient).to receive(:new).and_return(trs_client)
      allow(trs_client).to receive(:reopen_teacher_induction)
    end

    it "calls the TRS API to reopen the teacher's induction" do
      expect(trs_client).to receive(:reopen_teacher_induction).with(trn:, start_date:)
      described_class.new.perform(trn:, start_date:)
    end
  end
end
