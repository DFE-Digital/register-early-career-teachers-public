RSpec.describe ReopenInductionJob, type: :job do
  describe "#perform" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:trn) { teacher.trn }
    let(:start_date) { 1.year.ago }
    let(:trs_client) { instance_double(TRS::APIClient) }
    let(:refresh_service) { instance_double(Teachers::RefreshTRSAttributes) }

    before do
      allow(TRS::APIClient).to receive(:new).and_return(trs_client)
      allow(Teachers::RefreshTRSAttributes)
        .to receive(:new)
        .with(teacher, api_client: trs_client)
        .and_return(refresh_service)
      allow(trs_client).to receive(:reopen_teacher_induction!)
      allow(refresh_service).to receive(:refresh!)
    end

    it "calls the TRS API to reopen the teacher's induction" do
      expect(trs_client)
        .to receive(:reopen_teacher_induction!)
        .with(trn:, start_date:)

      described_class.new.perform(trn:, start_date:)
    end

    it "refreshes the teacher's TRS attributes" do
      expect(refresh_service).to receive(:refresh!)

      described_class.new.perform(trn:, start_date:)
    end
  end
end
