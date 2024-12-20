RSpec.describe Sessions::SessionUserBuilder do
  describe '#session_user' do
    let(:email) { Faker::Internet.email }
    let(:first_name) { Faker::Name.first_name }
    let(:last_name) { Faker::Name.last_name }
    let(:name) { [first_name, last_name].join(" ").strip }

    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
    let(:school) { FactoryBot.create(:school) }

    let(:omniauth_payload) do
      OpenStruct.new(
        provider:,
        info: OpenStruct.new(
          email:,
          first_name:,
          last_name:,
          appropriate_body_id:,
          school_urn:,
          dfe_staff:
        ),
        extra: OpenStruct.new(
          raw_info: OpenStruct.new(
            organisation: OpenStruct.new(
              id: organisation_id,
              urn: organisation_urn
            )
          )
        )
      )
    end

    subject { described_class.new(omniauth_payload:).session_user }

    context 'when the provider is dfe_sign_in and no organisation_urn present' do
      let(:provider) { 'dfe_sign_in' }
      let(:appropriate_body_id) { nil }
      let(:school_urn) { nil }
      let(:dfe_staff) { nil }
      let(:organisation_id) { appropriate_body.dfe_sign_in_organisation_id }
      let(:organisation_urn) { nil }

      it 'returns an appropriate body user' do
        expect(subject).to be_a(Sessions::AppropriateBodyUser)
      end
    end

    context 'when the provider is dfe_sign_in and the organisation_urn is present' do
      let(:provider) { 'dfe_sign_in' }
      let(:appropriate_body_id) { nil }
      let(:school_urn) { nil }
      let(:dfe_staff) { nil }
      let(:organisation_id) { Faker::Internet.uuid }
      let(:organisation_urn) { school.urn }

      it 'returns a school user' do
        expect(subject).to be_a(Sessions::SchoolUser)
      end
    end

    context 'when the provider is persona and the appropriate_body_id is present' do
      let(:provider) { 'persona' }
      let(:appropriate_body_id) { appropriate_body.id }
      let(:school_urn) { nil }
      let(:dfe_staff) { 'false' }
      let(:organisation_id) { nil }
      let(:organisation_urn) { nil }

      it 'returns a school user' do
        expect(subject).to be_a(Sessions::AppropriateBodyPersona)
      end
    end

    context 'when the provider is persona and the school_urn is present' do
      let(:provider) { 'persona' }
      let(:appropriate_body_id) { nil }
      let(:school_urn) { school.urn }
      let(:dfe_staff) { 'false' }
      let(:organisation_id) { nil }
      let(:organisation_urn) { nil }

      it 'returns a school persona' do
        expect(subject).to be_a(Sessions::SchoolPersona)
      end
    end

    context 'when the provider is persona and the dfe_staff is truthy' do
      let(:provider) { 'persona' }
      let(:appropriate_body_id) { nil }
      let(:school_urn) { nil }
      let(:dfe_staff) { 'true' }
      let(:organisation_id) { nil }
      let(:organisation_urn) { nil }

      let!(:user) { FactoryBot.create(:user, email:) }

      it 'returns a dfe persona' do
        expect(subject).to be_a(Sessions::DfEPersona)
      end
    end
  end
end
