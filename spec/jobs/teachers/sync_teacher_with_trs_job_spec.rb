RSpec.describe Teachers::SyncTeacherWithTRSJob, type: :job do
  describe "#perform" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:api_client) { instance_double(TRS::APIClient) }
    let(:refresh_service) { instance_double(Teachers::RefreshTRSAttributes, refresh!: refresh) }
    let(:replace_trn_service) { instance_double(Teachers::ReplaceTRN) }
    let(:refresh) { :teacher_updated }

    before do
      allow(TRS::APIClient).to receive(:new).and_return(api_client)
      allow(Teachers::RefreshTRSAttributes)
        .to receive(:new)
        .with(teacher, api_client:)
        .and_return(refresh_service)
      allow(Teachers::ReplaceTRN)
        .to receive(:new)
        .with(teacher:)
        .and_return(replace_trn_service)
    end

    it "calls the RefreshTRSAttributes service with the correct teacher" do
      expect(refresh_service).to receive(:refresh!)

      described_class.perform_now(teacher:)
    end

    it "uses the trs_sync queue" do
      expect(described_class.queue_name).to eq("trs_sync")
    end

    it "does not call the ReplaceTRN service if the teacher has not been merged" do
      expect(replace_trn_service).not_to receive(:replace!)

      described_class.perform_now(teacher:)
    end

    context "when the teacher is trnless" do
      let(:teacher) { FactoryBot.create(:teacher, :trnless) }

      it "does not call the RefreshTRSAttributes service" do
        expect(refresh_service).not_to receive(:refresh!)

        described_class.perform_now(teacher:)
      end
    end

    context "when the teacher is deactivated in TRS" do
      let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs) }

      it "does not call the RefreshTRSAttributes service" do
        expect(refresh_service).not_to receive(:refresh!)

        described_class.perform_now(teacher:)
      end
    end

    context "when the teacher is not found in TRS" do
      let(:teacher) { FactoryBot.create(:teacher, :not_found_in_trs) }

      it "does not call the RefreshTRSAttributes service" do
        expect(refresh_service).not_to receive(:refresh!)

        described_class.perform_now(teacher:)
      end
    end

    context "when the updated teacher has a TRS permanent redirect" do
      let(:refresh) { :teacher_merged }

      it "calls the ReplaceTRN service to replace the teacher's TRN" do
        expect(replace_trn_service).to receive(:replace!)

        described_class.perform_now(teacher:)
      end
    end
  end
end
