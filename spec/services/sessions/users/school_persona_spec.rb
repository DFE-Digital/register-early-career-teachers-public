RSpec.describe Sessions::Users::SchoolPersona do
  subject(:school_persona) do
    described_class.new(email:, name:, school_urn:, last_active_at:)
  end

  let!(:school) { FactoryBot.create(:school) }
  let(:email) { 'school_persona@email.com' }
  let(:last_active_at) { 4.minutes.ago }
  let(:name) { 'Christopher Lee' }
  let(:school_urn) { school.urn }

  it_behaves_like 'a session user' do
    let(:user_props) { { email:, name:, school_urn: school.urn } }
  end

  context 'when personas are disabled' do
    before { allow(Rails.application.config).to receive(:enable_personas).and_return(false) }

    it do
      expect { school_persona }.to raise_error(described_class::SchoolPersonaDisabledError)
    end
  end

  context 'when no school is found' do
    let(:school_urn) { 'A123456' }

    it do
      expect { school_persona }.to raise_error(described_class::UnknownSchoolURN, school_urn)
    end
  end

  describe '#provider' do
    it { expect(school_persona.provider).to be(:persona) }
  end

  describe '#user_type' do
    it { expect(school_persona.user_type).to be(:school_user) }
  end

  describe '#appropriate_body_user?' do
    it { expect(school_persona).not_to be_appropriate_body_user }
  end

  describe '#has_dfe_sign_in_role?' do
    it { expect(school_persona).not_to have_dfe_sign_in_role }
  end

  describe '#dfe_user?' do
    it { expect(school_persona).not_to be_dfe_user }
  end

  describe '#event_author_params' do
    it 'returns a hash with the attributes needed to record an event' do
      expect(school_persona.event_author_params).to eql({
        author_email: school_persona.email,
        author_name: school_persona.name,
        author_type: :school_user
      })
    end
  end

  describe '#name' do
    it 'returns the full name of the user' do
      expect(school_persona.name).to eql(name)
    end
  end

  describe '#organisation_name' do
    it 'returns the name of the school associated to the user' do
      expect(school_persona.organisation_name).to eq(school.name)
    end
  end

  describe '#school' do
    it 'returns the school of the user' do
      expect(school_persona.school).to eql(school)
    end
  end

  describe '#school_urn' do
    it 'returns the urn of the school of the user' do
      expect(school_persona.school_urn).to eql(school.urn)
    end
  end

  describe '#school_user?' do
    it { expect(school_persona).to be_school_user }
  end

  describe '#to_h' do
    it 'returns attributes for session storage' do
      expect(school_persona.to_h).to eql({
        'type' => 'Sessions::Users::SchoolPersona',
        'email' => email,
        'name' => name,
        'last_active_at' => last_active_at,
        'school_urn' => school.urn
      })
    end
  end

  describe '#user' do
    it { expect(school_persona.user).to be_nil }
  end
end
