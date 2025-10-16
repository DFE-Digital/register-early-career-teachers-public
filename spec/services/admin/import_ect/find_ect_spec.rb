RSpec.describe Admin::ImportECT::FindECT do
  subject(:find_ect) { Admin::ImportECT::FindECT.new(pending_induction_submission:) }

  let(:pending_induction_submission) do
    FactoryBot.create(:pending_induction_submission,
      appropriate_body: nil)
  end

  describe "#initialize" do
    it "assigns the provided pending induction submission params" do
      expect(find_ect.pending_induction_submission).to eql(pending_induction_submission)
    end
  end

  describe "#import_from_trs!" do
    context "when the pending_induction_submission is invalid" do
      let(:pending_induction_submission) do
        FactoryBot.create(:pending_induction_submission,
          date_of_birth: nil,
          appropriate_body: nil)
      end

      it do
        expect(find_ect.import_from_trs!).to be(false)
      end
    end

    context "when the teacher is required to complete" do
      include_context "test trs api client that finds teacher with specific induction status", "RequiredToComplete"

      it "saves attributes from TRS to the pending_induction_submission" do
        expect(find_ect.import_from_trs!).to be(true)
        pending_induction_submission.reload
        expect(pending_induction_submission.trs_first_name).to eq("Kirk")
        expect(pending_induction_submission.trs_last_name).to eq("Van Houten")
        expect(pending_induction_submission.trs_induction_status).to eq("RequiredToComplete")
      end
    end

    context "when teacher already exists in system" do
      include_context "test trs api client"

      before do
        FactoryBot.create(:teacher, trn: pending_induction_submission.trn)
      end

      it do
        expect { find_ect.import_from_trs! }.to raise_error(Admin::Errors::TeacherAlreadyExists)
      end
    end

    context "when no teacher is found" do
      include_context "test trs api client that finds nothing"

      it do
        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::TeacherNotFound)
      end
    end

    context "when the teacher is prohibited from teaching" do
      include_context "test trs api client that finds teacher prohibited from teaching"

      it do
        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::ProhibitedFromTeaching)
      end
    end

    context "when the teacher does not have QTS" do
      include_context "test trs api client that finds teacher without QTS"

      it do
        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::QTSNotAwarded)
      end
    end

    context "when the teacher has passed" do
      include_context "test trs api client that finds teacher with specific induction status", "Passed"

      it do
        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when the ECT has failed" do
      include_context "test trs api client that finds teacher with specific induction status", "Failed"

      it do
        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when the teacher is exempt" do
      include_context "test trs api client that finds teacher with specific induction status", "Exempt"

      it do
        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when teacher is deactivated" do
      include_context "test trs api client deactivated teacher"

      it do
        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::TeacherDeactivated)
      end
    end
  end
end
