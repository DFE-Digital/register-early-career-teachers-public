RSpec.describe Teachers::Manage do
  subject(:service) { described_class.new(author:, teacher:, appropriate_body:) }

  let(:user) { FactoryBot.create(:user, name: 'Christopher Biggins', email: 'christopher.biggins@education.gov.uk') }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Barry', trs_last_name: 'Allen') }
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

    it 'records a teacher attributes updated from TRS event' do
      freeze_time do
        service.update_trs_attributes!(trs_qts_status_description:, trs_qts_awarded_on:, trs_initial_teacher_training_provider_name:, trs_initial_teacher_training_end_date:, trs_data_last_refreshed_at:)

        expect(RecordEventJob).to have_received(:perform_later).with(
          author_email: 'christopher.biggins@education.gov.uk',
          author_id: author.id,
          author_name: 'Christopher Biggins',
          author_type: :dfe_staff_user,
          event_type: :teacher_attributes_updated_from_trs,
          happened_at: Time.zone.now,
          heading: "TRS attributes updated",
          teacher:,
          metadata: {
            trs_data_last_refreshed_at: [nil, Time.zone.now],
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
            "TRS data last refreshed at set to '#{Time.zone.now}'"
          ]
        )
      end
    end
  end
end
