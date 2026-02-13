RSpec.describe AppropriateBodies::ClaimAnECT::FindECT do
  subject(:find_ect) do
    AppropriateBodies::ClaimAnECT::FindECT.new(appropriate_body_period:, pending_induction_submission:)
  end

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }

  describe "#initialize" do
    it "assigns the provided appropriate body period and pending induction submission params" do
      expect(find_ect.appropriate_body_period).to eql(appropriate_body_period)
      expect(find_ect.pending_induction_submission).to eql(pending_induction_submission)
    end
  end

  describe "#import_from_trs!" do
    context "when the pending_induction_submission is invalid" do
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, date_of_birth: nil) }

      it do
        expect(find_ect.import_from_trs!).to be(false)
      end
    end

    context "when no teacher is found" do
      include_context "test TRS API returns nothing"

      it do
        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::TeacherNotFound)
      end
    end

    context "when the teacher is required to complete" do
      include_context "test TRS API returns a teacher with specific induction status", "RequiredToComplete"

      it "saves attributes from TRS to the pending_induction_submission" do
        expect(find_ect.import_from_trs!).to be(true)
        pending_induction_submission.reload
        expect(pending_induction_submission.trs_first_name).to eq("Kirk")
        expect(pending_induction_submission.trs_last_name).to eq("Van Houten")
        expect(pending_induction_submission.trs_induction_status).to eq("RequiredToComplete")
      end

      context "with an ongoing induction period" do
        let(:teacher) { FactoryBot.create(:teacher) }
        let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, trn: teacher.trn) }

        context "with another AB" do
          let(:other_appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }

          before do
            FactoryBot.create(:induction_period, :ongoing,
                              teacher:,
                              appropriate_body_period: other_appropriate_body_period,
                              started_on: Date.parse("2 October 2022"))
          end

          it do
            expect(find_ect.import_from_trs!).to be(true)
          end
        end

        context "with the same AB" do
          before do
            FactoryBot.create(:induction_period, :ongoing,
                              teacher:,
                              appropriate_body_period:,
                              started_on: Date.parse("2 October 2022"))
          end

          it do
            expect {
              find_ect.import_from_trs!
            }.to raise_error(AppropriateBodies::ClaimAnECT::FindECT::TeacherHasOngoingInductionPeriodWithCurrentAB)
          end
        end
      end
    end

    context "when the teacher has passed" do
      include_context "test TRS API returns a teacher with specific induction status", "Passed"

      it do
        expect {
          find_ect.import_from_trs!
        }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when the teacher has failed" do
      include_context "test TRS API returns a teacher with specific induction status", "Failed"

      it do
        expect {
          find_ect.import_from_trs!
        }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when the teacher is exempt" do
      include_context "test TRS API returns a teacher with specific induction status", "Exempt"

      it do
        expect {
          find_ect.import_from_trs!
        }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end
  end
end
