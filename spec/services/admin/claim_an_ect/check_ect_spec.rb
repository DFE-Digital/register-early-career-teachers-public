RSpec.describe Admin::ClaimAnECT::CheckECT do
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }
  let(:service) { described_class.new(pending_induction_submission:) }

  describe '#begin_claim!' do
    context 'when the ECT is valid for claiming' do
      it 'marks the pending induction submission as confirmed' do
        service.begin_claim!
        pending_induction_submission.reload

        expect(pending_induction_submission.confirmed).to be true
        expect(pending_induction_submission.confirmed_at).to be_present
      end

      it 'saves the pending induction submission' do
        expect { service.begin_claim! }.to change { pending_induction_submission.reload.confirmed }.from(false).to(true)
      end

      it 'returns true' do
        expect(service.begin_claim!).to be true
      end
    end

    context 'when the ECT has an ongoing induction period with another appropriate body' do
      let!(:existing_teacher) { FactoryBot.create(:teacher, trn: pending_induction_submission.trn) }
      let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher: existing_teacher) }

      it 'raises a TeacherHasActiveInductionPeriodWithAnotherAB error' do
        expect { service.begin_claim! }.to raise_error(Admin::Errors::TeacherHasActiveInductionPeriodWithAnotherAB)
      end
    end

    context 'when the ECT has a past induction period' do
      let!(:existing_teacher) { FactoryBot.create(:teacher, trn: pending_induction_submission.trn) }
      let!(:induction_period) { FactoryBot.create(:induction_period, :finished, teacher: existing_teacher) }

      it 'marks the pending induction submission as confirmed' do
        service.begin_claim!
        pending_induction_submission.reload

        expect(pending_induction_submission.confirmed).to be true
        expect(pending_induction_submission.confirmed_at).to be_present
      end
    end

    context 'when the ECT has no existing induction periods' do
      it 'marks the pending induction submission as confirmed' do
        service.begin_claim!
        pending_induction_submission.reload

        expect(pending_induction_submission.confirmed).to be true
        expect(pending_induction_submission.confirmed_at).to be_present
      end
    end
  end
end
