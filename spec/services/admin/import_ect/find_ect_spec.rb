RSpec.describe Admin::ImportECT::FindECT do
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, appropriate_body: nil) }

  describe "#initialize" do
    it "assigns the provided pending induction submission params" do
      find_ect = Admin::ImportECT::FindECT.new(pending_induction_submission:)

      expect(find_ect.pending_induction_submission).to eql(pending_induction_submission)
    end
  end

  describe "#import_from_trs!" do
    context "when the pending_induction_submission is invalid" do
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, date_of_birth: nil, appropriate_body: nil) }

      it "returns nil" do
        find_ect = Admin::ImportECT::FindECT.new(pending_induction_submission:)

        expect(find_ect.import_from_trs!).to be_nil
      end
    end

    context "when there is a match" do
      include_context 'test trs api client that finds teacher with specific induction status', 'RequiredToComplete'

      let(:find_ect) { Admin::ImportECT::FindECT.new(pending_induction_submission:) }

      it "makes a call to the TRS API client with the expected parameters" do
        allow(TRS::APIClient).to receive(:build).and_call_original

        find_ect.import_from_trs!

        expect(TRS::APIClient).to have_received(:build)
      end

      it "assigns the incoming attributes to the pending_induction_submission and returns it" do
        result = find_ect.import_from_trs!

        expect(result).to be(true)
        pending_induction_submission.reload
        expect(pending_induction_submission.trs_first_name).to eq('Kirk')
        expect(pending_induction_submission.trs_last_name).to eq('Van Houten')
        expect(pending_induction_submission.trs_induction_status).to eq('RequiredToComplete')
      end

      it "saves the pending_induction_submission with find_ect context" do
        expect(pending_induction_submission).to receive(:save).with(context: :find_ect)

        find_ect.import_from_trs!
      end
    end

    context "when teacher already exists in system" do
      include_context 'test trs api client'

      let!(:existing_teacher) { FactoryBot.create(:teacher, trn: pending_induction_submission.trn) }
      let(:find_ect) { Admin::ImportECT::FindECT.new(pending_induction_submission:) }

      it "raises TeacherAlreadyExists error" do
        expect { find_ect.import_from_trs! }.to raise_error do |error|
          expect(error).to be_a(Admin::Errors::TeacherAlreadyExists)
          expect(error.message).to match(/\A#<Teacher:/)
        end
      end
    end

    context "when there is no match" do
      include_context 'test trs api client that finds nothing'

      it "raises teacher not found error" do
        find_ect = Admin::ImportECT::FindECT.new(pending_induction_submission:)

        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::TeacherNotFound)
      end
    end

    context "when teacher is prohibited from teaching" do
      include_context 'test trs api client that finds teacher prohibited from teaching'

      it "raises prohibited from teaching error" do
        find_ect = Admin::ImportECT::FindECT.new(pending_induction_submission:)

        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::ProhibitedFromTeaching)
      end
    end

    context "when teacher does not have QTS" do
      include_context 'test trs api client that finds teacher without QTS'

      it "raises QTS not awarded error" do
        find_ect = Admin::ImportECT::FindECT.new(pending_induction_submission:)

        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::QTSNotAwarded)
      end
    end

    context "when teacher has completed induction" do
      include_context 'test trs api client that finds teacher with specific induction status', 'Passed'

      it "raises induction already completed error" do
        find_ect = Admin::ImportECT::FindECT.new(pending_induction_submission:)

        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when teacher has failed induction" do
      include_context 'test trs api client that finds teacher with specific induction status', 'Failed'

      it "raises induction already completed error" do
        find_ect = Admin::ImportECT::FindECT.new(pending_induction_submission:)

        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when teacher is exempt from induction" do
      include_context 'test trs api client that finds teacher with specific induction status', 'Exempt'

      it "raises induction already completed error" do
        find_ect = Admin::ImportECT::FindECT.new(pending_induction_submission:)

        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when teacher is deactivated" do
      include_context 'test trs api client deactivated teacher'

      it "raises teacher deactivated error" do
        find_ect = Admin::ImportECT::FindECT.new(pending_induction_submission:)

        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::TeacherDeactivated)
      end
    end
  end
end
