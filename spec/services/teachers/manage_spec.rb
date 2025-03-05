RSpec.describe Teachers::Manage do
  subject(:service) { described_class.new(author:, teacher:, appropriate_body:) }

  let(:user) { FactoryBot.create(:user, name: 'Christopher Biggins', email: 'christopher.biggins@education.gov.uk') }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Barry', trs_last_name: 'Allen') }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:trn) { '1234567' }

  describe '#update_teacher!' do
    before { allow(Events::Record).to receive(:teacher_record_created!).and_return(true) }
    before { allow(Events::Record).to receive(:teacher_name_changed_in_trs!).and_return(true) }

    context 'when the teacher is a new record' do
      let(:teacher) { Teacher.new(trn:) }

      it 'saves the teacher with the provided attributes' do
        expect {
          service.update_teacher!(trs_first_name: 'John', trs_last_name: 'Doe')
        }.to change(Teacher, :count).by(1)

        expect(teacher.trs_first_name).to eq('John')
        expect(teacher.trs_last_name).to eq('Doe')
      end

      it 'records a teacher_record_created event' do
        freeze_time do
          service.update_teacher!(trs_first_name: 'John', trs_last_name: 'Doe')

          expect(Events::Record).to have_received(:teacher_record_created!).with(
            author:,
            teacher:,
            appropriate_body:,
            trn: teacher.trn
          )
        end
      end
    end

    context 'when the teacher already exists' do
      it 'updates the teacher with the provided attributes' do
        service.update_teacher!(trs_first_name: 'John', trs_last_name: 'Doe')

        expect(teacher.trs_first_name).to eq('John')
        expect(teacher.trs_last_name).to eq('Doe')
      end

      it 'does not record a teacher_record_created event' do
        service.update_teacher!(trs_first_name: 'John', trs_last_name: 'Doe')
        expect(Events::Record).not_to have_received(:teacher_record_created!)
      end

      it 'records a name change event when the name changes' do
        # Create a new instance with fresh stubs for this test
        user = FactoryBot.create(:user, name: 'Christopher Biggins', email: 'christopher.biggins@education.gov.uk')
        author = Sessions::Users::DfEPersona.new(email: user.email)
        teacher = FactoryBot.create(:teacher, trs_first_name: 'Barry', trs_last_name: 'Allen')
        appropriate_body = FactoryBot.create(:appropriate_body)

        # Create a new service instance
        test_service = described_class.new(author:, teacher:, appropriate_body:)

        # Stub the Events::Record class
        allow(Events::Record).to receive(:teacher_name_changed_in_trs!)

        # Update the teacher's name
        test_service.update_teacher!(trs_first_name: 'John', trs_last_name: 'Doe')

        # Verify the method was called
        expect(Events::Record).to have_received(:teacher_name_changed_in_trs!).with(
          old_name: 'Barry Allen',
          new_name: 'John Doe',
          author:,
          teacher:,
          appropriate_body:
        )
      end

      it 'does not record a name change event when the name does not change' do
        service.update_teacher!(trs_qts_awarded_on: Date.new(2023, 5, 2))
        expect(Events::Record).not_to have_received(:teacher_name_changed_in_trs!)
      end

      it 'handles QTS award date changes' do
        old_date = Date.new(2022, 1, 1)
        new_date = Date.new(2023, 5, 2)

        teacher.trs_qts_awarded_on = old_date
        teacher.save!

        # Reset any tracking from the save
        teacher.reload

        # We're not actually recording QTS award date changes yet (commented out in the implementation)
        # but we should test that the method is called with the right parameters
        service.update_teacher!(trs_qts_awarded_on: new_date)

        expect(teacher.trs_qts_awarded_on).to eq(new_date)
      end
    end
  end
end
