RSpec.describe Teachers::Manage do
  subject(:service) { described_class.new(author:, teacher:, appropriate_body:) }

  let(:user) { FactoryBot.create(:user, name: 'Christopher Biggins', email: 'christopher.biggins@education.gov.uk') }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Barry', trs_last_name: 'Allen', trs_induction_status: 'InProgress') }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

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
          heading: "Name changed from 'Barry Allen' to 'John Doe'",
          teacher:
        )
      end
    end
  end

  describe '#update_trs_attributes!' do
    before { allow(RecordEventJob).to receive(:perform_later).and_return(true) }

    let(:trs_qts_status_description) { 'QTS status description' }
    let(:trs_qts_awarded_on) { 3.years.ago.to_date }
    let(:trs_initial_teacher_training_provider_name) { 'ITT provider' }
    let(:trs_initial_teacher_training_end_date) { 2.years.ago.to_date }
    let(:trs_data_last_refreshed_at) { Time.zone.now }

    context 'when something has changed' do
      it 'updates the teacher record' do
        expect(teacher.trs_qts_status_description).not_to eql(trs_qts_status_description)
        expect(teacher.trs_qts_awarded_on).not_to eql(trs_qts_awarded_on)
        expect(teacher.trs_initial_teacher_training_provider_name).not_to eql(trs_initial_teacher_training_provider_name)
        expect(teacher.trs_initial_teacher_training_end_date).not_to eql(trs_initial_teacher_training_end_date)

        service.update_trs_attributes!(trs_qts_status_description:, trs_qts_awarded_on:, trs_initial_teacher_training_provider_name:, trs_initial_teacher_training_end_date:, trs_data_last_refreshed_at:)

        expect(teacher.trs_qts_status_description).to eql(trs_qts_status_description)
        expect(teacher.trs_qts_awarded_on).to eql(trs_qts_awarded_on)
        expect(teacher.trs_initial_teacher_training_provider_name).to eql(trs_initial_teacher_training_provider_name)
        expect(teacher.trs_initial_teacher_training_end_date).to eql(trs_initial_teacher_training_end_date)
      end

      it 'records a teacher attributes updated event from TRS event' do
        freeze_time do
          service.update_trs_attributes!(trs_qts_status_description:, trs_qts_awarded_on:, trs_initial_teacher_training_provider_name:, trs_initial_teacher_training_end_date:, trs_data_last_refreshed_at:)

          expect(RecordEventJob).to have_received(:perform_later).with(
            author_email: 'christopher.biggins@education.gov.uk',
            author_id: author.id,
            author_name: 'Christopher Biggins',
            author_type: :dfe_staff_user,
            event_type: :teacher_trs_attributes_updated,
            happened_at: Time.zone.now,
            heading: "TRS attributes updated",
            teacher:,
            metadata: {
              trs_initial_teacher_training_end_date: [nil, 2.years.ago.to_date],
              trs_initial_teacher_training_provider_name: [nil, "ITT provider"],
              trs_qts_awarded_on: [nil, 3.years.ago.to_date],
              trs_qts_status_description: [nil, "QTS status description"]
            }.with_indifferent_access,
            modifications: [
              "TRS qts awarded on set to '#{3.years.ago.to_date.to_fs(:govuk_short)}'",
              "TRS qts status description set to 'QTS status description'",
              "TRS initial teacher training provider name set to 'ITT provider'",
              "TRS initial teacher training end date set to '#{2.years.ago.to_date.to_fs(:govuk_short)}'",
            ]
          )
        end
      end

      it 'updates the trs_data_last_refreshed_at on the teacher' do
        refresh_time = 2.hours.ago

        service.update_trs_attributes!(
          trs_qts_status_description:,
          trs_qts_awarded_on:,
          trs_initial_teacher_training_provider_name:,
          trs_initial_teacher_training_end_date:,
          trs_data_last_refreshed_at: refresh_time
        )

        teacher.reload

        expect(teacher.trs_data_last_refreshed_at).to be_within(1.second).of(refresh_time)
      end
    end

    context 'when nothing has changed' do
      let(:attrs) do
        {
          trs_qts_status_description: 'QTS status description',
          trs_qts_awarded_on: 3.years.ago.to_date,
          trs_initial_teacher_training_provider_name: 'ITT provider',
          trs_initial_teacher_training_end_date: 2.years.ago.to_date,
          trs_data_last_refreshed_at: 1.hour.ago
        }
      end

      it 'does not record a teacher attributes updated event' do
        teacher.update!(**attrs)

        service.update_trs_attributes!(**attrs)

        expect(RecordEventJob).not_to have_received(:perform_later)
      end

      it 'does update the trs_data_last_refreshed_at on the teacher' do
        teacher.update!(**attrs.merge(trs_data_last_refreshed_at: 2.hours.ago))

        service.update_trs_attributes!(**attrs)

        expect(teacher.trs_data_last_refreshed_at).to be_within(1.second).of(1.hour.ago)
      end
    end
  end

  describe '#update_trs_induction_status!' do
    before { allow(RecordEventJob).to receive(:perform_later).and_return(true) }

    context 'when the new induction status is different' do
      it 'updates the teacher record' do
        service.update_trs_induction_status!(trs_induction_status: 'Passed')

        expect(teacher.trs_induction_status).to eql('Passed')
      end

      it 'records an event' do
        freeze_time do
          service.update_trs_induction_status!(trs_induction_status: 'Passed')

          expect(RecordEventJob).to have_received(:perform_later).with(
            author_email: 'christopher.biggins@education.gov.uk',
            author_id: author.id,
            author_name: 'Christopher Biggins',
            author_type: :dfe_staff_user,
            event_type: :teacher_trs_induction_status_updated,
            appropriate_body:,
            teacher:,
            happened_at: Time.zone.now,
            heading: %(Induction status changed from 'InProgress' to 'Passed')
          )
        end
      end
    end

    context 'when the new induction status is the same' do
      it 'does not records an event' do
        service.update_trs_induction_status!(trs_induction_status: 'InProgress')

        expect(RecordEventJob).not_to have_received(:perform_later)
      end
    end
  end

  describe '#update_qts_awarded_on!' do
    before { allow(RecordEventJob).to receive(:perform_later).and_return(true) }

    context 'when the new induction status is different' do
      it 'updates the teacher record' do
        service.update_qts_awarded_on!(trs_qts_awarded_on: 1.year.ago)

        expect(teacher.trs_qts_awarded_on).to eql(1.year.ago.to_date)
      end

      it 'does not records an event' do
        service.update_qts_awarded_on!(trs_qts_awarded_on: 1.year.ago)

        expect(RecordEventJob).not_to have_received(:perform_later)
      end
    end
  end

  describe '#update_itt_provider_name!' do
    before { allow(RecordEventJob).to receive(:perform_later).and_return(true) }

    context 'when the new induction status is different' do
      it 'updates the teacher record' do
        service.update_itt_provider_name!(trs_initial_teacher_training_provider_name: 'Some other training provider')

        expect(teacher.trs_initial_teacher_training_provider_name).to eql('Some other training provider')
      end

      it 'does not records an event' do
        service.update_qts_awarded_on!(trs_qts_awarded_on: 1.year.ago)

        expect(RecordEventJob).not_to have_received(:perform_later)
      end
    end
  end

  describe '#mark_teacher_as_deactivated!' do
    let(:author) { Events::SystemAuthor.new }
    let(:trs_data_last_refreshed_at) { 2.minutes.ago }

    context 'when the teacher is already deactivated' do
      let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs) }

      it 'fails with a Teachers::Manage::AlreadyDeactivated error' do
        expect { service.mark_teacher_as_deactivated!(trs_data_last_refreshed_at:) }.to raise_error(Teachers::Manage::AlreadyDeactivated)
      end
    end

    context 'when the teacher is active' do
      it 'sets the trs_deactivated flag to true' do
        expect(teacher.trs_deactivated).to be(false)

        service.mark_teacher_as_deactivated!(trs_data_last_refreshed_at:)
        teacher.reload

        expect(teacher.trs_data_last_refreshed_at).to be_within(0.001.seconds).of(trs_data_last_refreshed_at)
        expect(teacher.trs_deactivated).to be(true)
      end
    end
  end
end
