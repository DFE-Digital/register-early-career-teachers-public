RSpec.describe AppropriateBodies::ClaimAnECT::FindECT do
  subject(:find_ect) do
    AppropriateBodies::ClaimAnECT::FindECT.new(appropriate_body:, pending_induction_submission:)
  end

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }

  describe '#initialize' do
    it 'assigns the provided appropriate body and pending induction submission params' do
      expect(find_ect.appropriate_body).to eql(appropriate_body)
      expect(find_ect.pending_induction_submission).to eql(pending_induction_submission)
    end
  end

  describe '#import_from_trs!' do
    context 'when the pending_induction_submission is invalid' do
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, date_of_birth: nil) }

      it do
        expect(find_ect.import_from_trs!).to be(false)
      end
    end

    context 'when no teacher is found' do
      include_context 'test trs api client that finds nothing'

      it do
        expect { find_ect.import_from_trs! }.to raise_error(TRS::Errors::TeacherNotFound)
      end
    end

    context 'when the teacher is required to complete' do
      include_context 'test trs api client that finds teacher with specific induction status', 'RequiredToComplete'

      it 'saves attributes from TRS to the pending_induction_submission' do
        expect(find_ect.import_from_trs!).to be(true)
        pending_induction_submission.reload
        expect(pending_induction_submission.trs_first_name).to eq('Kirk')
        expect(pending_induction_submission.trs_last_name).to eq('Van Houten')
        expect(pending_induction_submission.trs_induction_status).to eq('RequiredToComplete')
      end

      context 'with an ongoing induction period' do
        let(:teacher) { FactoryBot.create(:teacher) }
        let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, trn: teacher.trn) }

        context 'with another AB' do
          before do
            FactoryBot.create(:induction_period, :ongoing,
                              teacher:,
                              appropriate_body: FactoryBot.create(:appropriate_body),
                              started_on: Date.parse('2 October 2022'))
          end

          it do
            expect(find_ect.import_from_trs!).to be(true)
          end
        end

        context 'with the same AB' do
          before do
            FactoryBot.create(:induction_period, :ongoing,
                              teacher:,
                              appropriate_body:,
                              started_on: Date.parse('2 October 2022'))
          end

          it do
            expect {
              find_ect.import_from_trs!
            }.to raise_error(AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithCurrentAB)
          end
        end
      end
    end

    context 'when the teacher has passed' do
      include_context 'test trs api client that finds teacher with specific induction status', 'Passed'

      it do
        expect {
          find_ect.import_from_trs!
        }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context 'when the teacher has failed' do
      include_context 'test trs api client that finds teacher with specific induction status', 'Failed'

      it do
        expect {
          find_ect.import_from_trs!
        }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context 'when the teacher is exempt' do
      include_context 'test trs api client that finds teacher with specific induction status', 'Exempt'

      it do
        expect {
          find_ect.import_from_trs!
        }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end
  end
end
