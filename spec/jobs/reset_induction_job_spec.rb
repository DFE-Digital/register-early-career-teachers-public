RSpec.describe ResetInductionJob, type: :job do
  describe "#perform" do
    let(:trn) { "1234567" }
    let(:trs_client) { instance_double(TRS::APIClient) }

    before do
      allow(TRS::APIClient).to receive(:new).and_return(trs_client)
      allow(trs_client).to receive(:reset_teacher_induction)
    end

    it "calls the TRS API to reset the teacher's induction" do
      expect(trs_client).to receive(:reset_teacher_induction).with(trn:)
      described_class.new.perform(trn:)
    end
  end
end
