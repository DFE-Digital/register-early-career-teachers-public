RSpec.describe Sessions::Users::Builder do
  describe '#session_user' do
    subject { described_class.new(omniauth_payload:).session_user }

    let(:email) { Faker::Internet.email }
    let(:appropriate_body) { create(:appropriate_body) }
    let(:school) { create(:school) }

    let(:omniauth_payload) do
      OmniAuth::AuthHash.new(
        provider:,
        uid:,
        info: {
          email:,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          name: Faker::Name.name,
          appropriate_body_id:,
          school_urn:,
          dfe_staff:
        },
        extra: {
          raw_info: {
            organisation: {
              id: organisation_id,
              urn: organisation_urn
            }
          }
        }
      )
    end

    context 'when the provider is :dfe_sign_in' do
      let(:provider) { 'dfe_sign_in' }

      context 'when the organisation_id matches an appropriate body record' do
        let(:uid) { Faker::Internet.uuid }
        let(:appropriate_body_id) { nil }
        let(:school_urn) { nil }
        let(:dfe_staff) { nil }
        let(:organisation_id) { appropriate_body.dfe_sign_in_organisation_id }
        let(:organisation_urn) { nil }

        it 'returns an appropriate body user' do
          expect(subject).to be_a(Sessions::Users::AppropriateBodyUser)
        end
      end

      context 'when the organisation_urn matches an school record' do
        let(:uid) { Faker::Internet.uuid }
        let(:appropriate_body_id) { nil }
        let(:school_urn) { nil }
        let(:dfe_staff) { nil }
        let(:organisation_id) { Faker::Internet.uuid }
        let(:organisation_urn) { school.urn }

        it 'returns a school user' do
          expect(subject).to be_a(Sessions::Users::SchoolUser)
        end
      end

      context "when organisation doesn't match an appropriate body or school" do
        let(:uid) { Faker::Internet.uuid }
        let(:appropriate_body_id) { nil }
        let(:school_urn) { nil }
        let(:dfe_staff) { nil }
        let(:organisation_id) { 'c399f5a7-44e4-4c86-bb4a-e3e2dbe69421' }
        let(:organisation_urn) { nil }

        it 'raises an UnknownOrganisation error' do
          expect { subject }.to raise_error(described_class::UnknownOrganisation,
                                            OmniAuth::AuthHash.new(omniauth_payload.extra.raw_info.organisation)
                                                              .to_s)
        end
      end
    end

    context 'when the provider is :persona' do
      let(:provider) { 'persona' }

      context 'when personas are not enabled' do
        let(:uid) { email }
        let(:appropriate_body_id) { nil }
        let(:school_urn) { nil }
        let(:dfe_staff) { 'true' }
        let(:organisation_id) { nil }
        let(:organisation_urn) { nil }
        let!(:user) { create(:user, email:) }

        before do
          allow(Rails.application.config).to receive(:enable_personas).and_return(false)
        end

        it 'raises an UnknownProvider error' do
          expect { subject }.to raise_error(described_class::UnknownProvider, provider)
        end
      end

      context 'when personas are enabled' do
        before do
          allow(Rails.application.config).to receive(:enable_personas).and_return(true)
        end

        context 'when dfe_staff is truthy' do
          let(:uid) { email }
          let(:appropriate_body_id) { nil }
          let(:school_urn) { nil }
          let(:dfe_staff) { 'true' }
          let(:organisation_id) { nil }
          let(:organisation_urn) { nil }
          let!(:user) { create(:user, email:) }

          it 'returns a dfe persona' do
            expect(subject).to be_a(Sessions::Users::DfEPersona)
          end
        end

        context 'when the school_urn is present' do
          let(:uid) { email }
          let(:appropriate_body_id) { nil }
          let(:school_urn) { school.urn }
          let(:dfe_staff) { 'false' }
          let(:organisation_id) { nil }
          let(:organisation_urn) { nil }

          it 'returns a school persona' do
            expect(subject).to be_a(Sessions::Users::SchoolPersona)
          end
        end

        context 'when the appropriate_body_id is present' do
          let(:uid) { email }
          let(:appropriate_body_id) { appropriate_body.id }
          let(:school_urn) { nil }
          let(:dfe_staff) { 'false' }
          let(:organisation_id) { nil }
          let(:organisation_urn) { nil }

          it 'returns an appropriate body persona' do
            expect(subject).to be_a(Sessions::Users::AppropriateBodyPersona)
          end
        end

        context 'when no dfe_staff or school_urn or appropriate_body_id present' do
          let(:uid) { email }
          let(:appropriate_body_id) { nil }
          let(:school_urn) { nil }
          let(:dfe_staff) { 'false' }
          let(:organisation_id) { nil }
          let(:organisation_urn) { nil }

          it 'raises an UnknownPersonaType error' do
            expect { subject }.to raise_error(described_class::UnknownPersonaType)
          end
        end
      end
    end

    context 'when the provider is not :dfe_sign_in or :persona' do
      let(:provider) { 'any_other_provider' }
      let(:uid) { email }
      let(:appropriate_body_id) { nil }
      let(:school_urn) { nil }
      let(:dfe_staff) { 'true' }
      let(:organisation_id) { nil }
      let(:organisation_urn) { nil }
      let!(:user) { create(:user, email:) }

      it 'raises an UnknownProvider error' do
        expect { subject }.to raise_error(described_class::UnknownProvider, provider)
      end
    end
  end
end
