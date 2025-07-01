RSpec.describe Admin::CheckTeacher do
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }

  describe '#import_teacher!' do
    context 'when the pending submission is valid' do
      before do
        allow(Events::Record).to receive(:teacher_imported_from_trs_event!)
      end

      it 'creates a teacher record and destroys the pending submission' do
        service = described_class.new(pending_induction_submission:, author:)

        expect { service.import_teacher! }.to change(Teacher, :count).by(1)
                                          .and change(PendingInductionSubmission, :count).by(-1)

        expect(service.teacher).to be_a(Teacher)
        expect(service.teacher.trn).to eq(pending_induction_submission.trn)
      end

      it 'records the import event' do
        service = described_class.new(pending_induction_submission:, author:)
        service.import_teacher!

        expect(Events::Record).to have_received(:teacher_imported_from_trs_event!).with(
          author:,
          teacher: service.teacher
        )
      end

      it 'returns true' do
        service = described_class.new(pending_induction_submission:, author:)

        expect(service.import_teacher!).to be(true)
      end
    end

    context 'when teacher creation fails' do
      let(:existing_teacher) { FactoryBot.create(:teacher) }
      let(:pending_induction_submission) do
        FactoryBot.create(:pending_induction_submission, trn: existing_teacher.trn)
      end

      it 'does not create a teacher record' do
        service = described_class.new(pending_induction_submission:, author:)

        expect { service.import_teacher! }.not_to change(Teacher, :count)
      end

      it 'returns false' do
        service = described_class.new(pending_induction_submission:, author:)

        expect(service.import_teacher!).to be(false)
      end
    end
  end
end
