RSpec.describe Admin::ClaimAnECT::FindECT do
  include_context 'fake trs api client'

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }
  let(:service) { described_class.new(pending_induction_submission:) }

  describe '#import_from_trs!' do
    context 'when the pending induction submission is valid' do
      it 'imports teacher data from TRS' do
        expect(service.import_from_trs!).to be true
      end

      it 'updates the pending induction submission with TRS data' do
        service.import_from_trs!
        pending_induction_submission.reload

        expect(pending_induction_submission.trs_first_name).to eq('Joe')
        expect(pending_induction_submission.trs_last_name).to eq('Bloggs')
        expect(pending_induction_submission.trs_date_of_birth).to eq(Date.parse('1990-12-25'))
        expect(pending_induction_submission.trs_email_address).to eq('joe.bloggs@example.com')
      end

      it 'saves the pending induction submission' do
        expect { service.import_from_trs! }.to change(PendingInductionSubmission, :count).by(1)
      end
    end

    context 'when the pending induction submission is invalid' do
      let(:pending_induction_submission) { FactoryBot.build(:pending_induction_submission, trn: nil) }

      it 'does not import data' do
        expect(service.import_from_trs!).to be false
      end

      it 'does not save the pending induction submission' do
        expect { service.import_from_trs! }.not_to change(PendingInductionSubmission, :count)
      end
    end

    context 'when the teacher already exists in the system' do
      let!(:existing_teacher) { FactoryBot.create(:teacher, trn: pending_induction_submission.trn) }

      it 'raises a TeacherAlreadyExists error' do
        expect { service.import_from_trs! }.to raise_error(Admin::Errors::TeacherAlreadyExists)
      end
    end

    context 'when the teacher is prohibited from teaching' do
      include_context 'fake trs api client that finds teacher prohibited from teaching'

      it 'raises a TRS eligibility error' do
        expect { service.import_from_trs! }.to raise_error(TRS::Errors::TRSEligibilityError)
      end
    end

    context 'when the teacher is not found in TRS' do
      include_context 'fake trs api client that finds nothing'

      it 'does not import data' do
        expect(service.import_from_trs!).to be false
      end

      it 'adds an error to the pending induction submission' do
        service.import_from_trs!
        expect(pending_induction_submission.errors[:base]).to include('No teacher with this TRN and date of birth was found')
      end
    end
  end
end
