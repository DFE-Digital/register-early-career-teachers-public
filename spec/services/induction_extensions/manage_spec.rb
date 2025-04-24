RSpec.describe InductionExtensions::Manage do
  subject(:service) do
    described_class.new(author:, teacher:, appropriate_body:)
  end

  let(:author) do
    Sessions::Users::AppropriateBodyPersona.new(
      email: user.email,
      name: user.name,
      appropriate_body_id: appropriate_body.id
    )
  end

  let(:user) { FactoryBot.create(:user, name: 'Christopher Biggins', email: 'christopher.biggins@education.gov.uk') }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Andy', trs_last_name: 'Zaltzman') }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe '#create_or_update!' do
    before { allow(RecordEventJob).to receive(:perform_later).and_return(true) }

    context 'when adding an extension' do
      it 'records a create event' do
        freeze_time do
          service.create_or_update!(id: nil, number_of_terms: '1')

          expect(teacher.induction_extensions.count).to eq(1)
          expect(teacher.induction_extensions.last.number_of_terms).to eq(1)

          expect(RecordEventJob).to have_received(:perform_later).with(
            appropriate_body:,
            author_email: 'christopher.biggins@education.gov.uk',
            author_name: 'Christopher Biggins',
            author_type: :appropriate_body_user,
            event_type: :induction_extension_created,
            happened_at: Time.zone.now,
            heading: "Andy Zaltzman's induction extended by 1.0 terms",
            teacher:,
            metadata: {},
            modifications: [],
            induction_extension: kind_of(InductionExtension)
          )
        end
      end
    end

    context 'when editing an extension' do
      let!(:induction_extension) { FactoryBot.create(:induction_extension, teacher:) }

      it 'records an update event' do
        freeze_time do
          service.create_or_update!(id: induction_extension.id, number_of_terms: '4.6')

          expect(induction_extension.reload.number_of_terms).to eq(4.6)

          expect(RecordEventJob).to have_received(:perform_later).with(
            appropriate_body:,
            author_email: 'christopher.biggins@education.gov.uk',
            author_name: 'Christopher Biggins',
            author_type: :appropriate_body_user,
            event_type: :induction_extension_updated,
            happened_at: Time.zone.now,
            heading: "Andy Zaltzman's induction extended by 4.6 terms",
            teacher:,
            metadata: {},
            modifications: [],
            induction_extension: kind_of(InductionExtension)
          )
        end
      end
    end
  end
end
