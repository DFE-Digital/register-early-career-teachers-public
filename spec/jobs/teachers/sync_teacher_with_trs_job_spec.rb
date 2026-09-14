RSpec.describe Teachers::SyncTeacherWithTRSJob, type: :job do
  describe "#perform" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:refresh_service) { instance_double(Teachers::RefreshTRSAttributes, refresh!: :teacher_updated) }
    let(:replace_trn_service) { instance_double(Teachers::ReplaceTRN) }
    let(:merge_trn_service) { instance_double(Teachers::MergeTRN) }

    before do
      allow(Teachers::ReplaceTRN)
        .to receive(:new)
        .with(teacher:)
        .and_return(replace_trn_service)
      allow(Teachers::MergeTRN)
        .to receive(:new)
        .with(teacher:)
        .and_return(merge_trn_service)
    end

    context "when the TRS API can find a teacher" do
      let(:api_client) { instance_double(TRS::APIClient) }

      before do
        allow(TRS::APIClient).to receive(:new).and_return(api_client)

        allow(Teachers::RefreshTRSAttributes)
          .to receive(:new)
          .with(teacher, api_client:)
          .and_return(refresh_service)
      end

      it "calls the RefreshTRSAttributes service with the correct teacher" do
        expect(refresh_service).to receive(:refresh!)

        described_class.perform_now(teacher:)
      end

      it "uses the trs_sync queue" do
        expect(described_class.queue_name).to eq("trs_sync")
      end

      it "does not call the ReplaceTRN or MergeTRN service if the teacher has not been merged" do
        expect(replace_trn_service).not_to receive(:replace!)
        expect(merge_trn_service).not_to receive(:merge!)

        described_class.perform_now(teacher:)
      end
    end

    context "when the teacher is trnless" do
      let(:teacher) { FactoryBot.create(:teacher, :trnless) }

      before do
        allow(Teachers::RefreshTRSAttributes)
          .to receive(:new)
          .with(teacher)
          .and_return(refresh_service)
      end

      it "does not call the RefreshTRSAttributes service" do
        expect(refresh_service).not_to receive(:refresh!)

        described_class.perform_now(teacher:)
      end
    end

    context "when the teacher is deactivated in TRS" do
      let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs) }

      before do
        allow(Teachers::RefreshTRSAttributes)
          .to receive(:new)
          .with(teacher)
          .and_return(refresh_service)
      end

      it "does not call the RefreshTRSAttributes service" do
        expect(refresh_service).not_to receive(:refresh!)

        described_class.perform_now(teacher:)
      end
    end

    context "when the teacher is not found in TRS" do
      let(:teacher) { FactoryBot.create(:teacher, :not_found_in_trs) }

      before do
        allow(Teachers::RefreshTRSAttributes)
          .to receive(:new)
          .with(teacher)
          .and_return(refresh_service)
      end

      it "does not call the RefreshTRSAttributes service" do
        expect(refresh_service).not_to receive(:refresh!)

        described_class.perform_now(teacher:)
      end
    end

    context "when the updated teacher has a TRS permanent redirect" do
      include_context "test TRS API returns a merged teacher"

      context "when there is no existing teacher with the redirected TRN" do
        it "calls the ReplaceTRN service to replace the teacher's TRN" do
          expect(replace_trn_service).to receive(:replace!)

          described_class.perform_now(teacher:)
        end
      end

      context "when there is an existing teacher with the redirected TRN" do
        let!(:existing_teacher) { FactoryBot.create(:teacher, trn: TRS::TestAPIClient::MERGED_TRN_REDIRECTS_TO) }

        it "calls the MergeTRN service to merge the teacher's TRN" do
          expect(merge_trn_service).to receive(:merge!)

          described_class.perform_now(teacher:)
        end
      end
    end
  end
end
