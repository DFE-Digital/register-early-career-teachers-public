RSpec.describe Teachers::Manage do
  subject(:service) { described_class.new(author:, teacher:, appropriate_body:) }

  let(:user) { FactoryBot.create(:user, name: 'Christopher Biggins', email: 'christopher.biggins@education.gov.uk') }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Barry', trs_last_name: 'Allen') }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:event_metadata) { { author:, appropriate_body: } }

  describe '.find_or_initialize_by' do
    before { allow(RecordEventJob).to receive(:perform_later).and_return(true) }

    context 'when the teacher does not exist' do
      let(:trn) { '1234567' }
      let(:trs_first_name) { 'John' }
      let(:trs_last_name) { 'Doe' }

      it 'creates a new teacher and records a creation event' do
        freeze_time do
          expect {
            described_class.find_or_initialize_by(
              trn:,
              trs_first_name:,
              trs_last_name:,
              event_metadata:
            )
          }.to change(Teacher, :count).by(1)

          teacher = Teacher.find_by(trn:)
          expect(teacher.trs_first_name).to eq(trs_first_name)
          expect(teacher.trs_last_name).to eq(trs_last_name)

          expect(RecordEventJob).to have_received(:perform_later).with(
            author_email: 'christopher.biggins@education.gov.uk',
            author_id: author.id,
            author_name: 'Christopher Biggins',
            author_type: :dfe_staff_user,
            event_type: :teacher_created_in_trs,
            happened_at: Time.zone.now,
            heading: "John Doe was created in TRS",
            teacher:,
            appropriate_body:
          )
        end
      end
    end

    context 'when the teacher already exists' do
      let(:existing_teacher) { FactoryBot.create(:teacher, trs_first_name: 'Existing', trs_last_name: 'Teacher') }

      it 'does not create a new teacher or record a creation event' do
        allow(Teacher).to receive(:find_by).and_return(existing_teacher)
        allow(existing_teacher).to receive(:new_record?).and_return(false)

        result = described_class.find_or_initialize_by(
          trn: existing_teacher.trn,
          trs_first_name: 'New',
          trs_last_name: 'Name',
          event_metadata:
        )

        expect(result.teacher).to eq(existing_teacher)
        expect(RecordEventJob).not_to have_received(:perform_later).with(
          hash_including(event_type: :teacher_created_in_trs)
        )
      end

      it 'returns a manage instance with the existing teacher' do
        manage = described_class.find_or_initialize_by(
          trn: existing_teacher.trn,
          trs_first_name: 'New',
          trs_last_name: 'Name',
          event_metadata:
        )

        expect(manage.teacher).to eq(existing_teacher)
        expect(manage.author).to eq(author)
        expect(manage.appropriate_body).to eq(appropriate_body)
      end
    end
  end

  describe '#update_name!' do
    before { allow(RecordEventJob).to receive(:perform_later).and_return(true) }

    it 'records a name change event' do
      freeze_time do
        service.update_name!(trs_first_name: 'John', trs_last_name: 'Doe')

        expect(RecordEventJob).to have_received(:perform_later).with(
          appropriate_body:,
          author_email: 'christopher.biggins@education.gov.uk',
          author_id: author.id,
          author_name: 'Christopher Biggins',
          author_type: :dfe_staff_user,
          event_type: :teacher_name_updated_by_trs,
          happened_at: Time.zone.now,
          heading: 'Name changed from Barry Allen to John Doe',
          teacher:
        )
      end
    end
  end

  describe '#update_qts_awarded_on!' do
    before { allow(RecordEventJob).to receive(:perform_later).and_return(true) }

    it 'records a QTS award date change event' do
      old_award_date = Date.new(2020, 1, 1)
      new_award_date = Date.new(2020, 2, 1)
      teacher.trs_qts_awarded_on = old_award_date

      freeze_time do
        service.update_qts_awarded_on!(trs_qts_awarded_on: new_award_date)

        expect(RecordEventJob).to have_received(:perform_later).with(
          hash_including(
            appropriate_body:,
            author_email: 'christopher.biggins@education.gov.uk',
            author_id: author.id,
            author_name: 'Christopher Biggins',
            author_type: :dfe_staff_user,
            event_type: :qts_awarded_on_updated_by_trs,
            happened_at: Time.zone.now,
            heading: "QTS award date changed from #{old_award_date} to #{new_award_date}",
            teacher:
          )
        )
      end
    end
  end

  describe '#update_itt_provider_name!' do
    before { allow(RecordEventJob).to receive(:perform_later).and_return(true) }

    it 'records an ITT provider name change event' do
      itt_provider_before = 'Old ITT Provider'
      itt_provider_after = 'New ITT Provider'
      teacher.trs_initial_teacher_training_provider_name = itt_provider_before

      freeze_time do
        service.update_itt_provider_name!(trs_initial_teacher_training_provider_name: itt_provider_after)

        expect(RecordEventJob).to have_received(:perform_later).with(
          hash_including(
            appropriate_body:,
            author_email: 'christopher.biggins@education.gov.uk',
            author_id: author.id,
            author_name: 'Christopher Biggins',
            author_type: :dfe_staff_user,
            event_type: :itt_provider_name_updated_by_trs,
            happened_at: Time.zone.now,
            heading: "ITT provider name changed from #{itt_provider_before} to #{itt_provider_after}",
            teacher:
          )
        )
      end
    end
  end
end
