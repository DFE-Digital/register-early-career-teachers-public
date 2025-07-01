RSpec.describe Admin::FindECT do
  describe "#initialize" do
    let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }

    it "assigns the provided pending induction submission params" do
      find_ect = Admin::FindECT.new(pending_induction_submission:)

      expect(find_ect.pending_induction_submission).to eql(pending_induction_submission)
    end
  end

  describe "#import_from_trs!" do
    context "when the pending_induction_submission is invalid" do
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, date_of_birth: nil) }

      it "returns nil" do
        find_ect = Admin::FindECT.new(pending_induction_submission:)

        expect(find_ect.import_from_trs!).to be_nil
      end
    end

    context "when teacher already exists" do
      include_context 'fake trs api client'
      let(:teacher) { FactoryBot.create(:teacher) }
      let!(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, trn: teacher.trn) }

      it "raises TeacherAlreadyExists error" do
        find_ect = Admin::FindECT.new(pending_induction_submission:)

        expect { find_ect.import_from_trs! }.to raise_error(AppropriateBodies::Errors::TeacherAlreadyExists)
      end
    end

    context "when teacher has invalid induction status" do
      include_context 'fake trs api client that finds teacher that has passed their induction'
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }

      it "raises InductionStatusInvalid error for Passed status" do
        find_ect = Admin::FindECT.new(pending_induction_submission:)

        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::InductionStatusInvalid)
      end
    end

    context "when teacher has valid induction status" do
      include_context 'fake trs api client that finds teacher with specific induction status', 'InProgress'
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }

      it "successfully imports the teacher" do
        find_ect = Admin::FindECT.new(pending_induction_submission:)

        expect(find_ect.import_from_trs!).to be(true)
      end
    end

    context "when there is no match" do
      include_context "fake trs api client that finds nothing"

      it "raises teacher not found error" do
        pending_induction_submission = FactoryBot.create(:pending_induction_submission)
        find_ect = Admin::FindECT.new(pending_induction_submission:)

        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::TeacherNotFound)
      end
    end
  end
end
