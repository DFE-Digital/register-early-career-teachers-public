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
          heading: 'Name changed from Barry Allen to John Doe',
          teacher:
        )
      end
    end
  end
end
