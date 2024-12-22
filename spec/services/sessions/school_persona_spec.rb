require_relative 'session_user_context'

RSpec.describe Sessions::Users::SchoolPersona do
  let(:email) { 'school_persona@email.com' }
  let(:name) { 'Christopher Lee' }
  let(:school_urn) { FactoryBot.create(:school).urn }
  let(:last_active_at) { 4.minutes.ago }

  subject(:school_persona) { described_class.new(email:, name:, school_urn:, last_active_at:) }

  it_behaves_like 'a session user' do
    let(:user_props) { { email:, name:, school_urn: } }
  end

  describe '.PROVIDER' do
    it 'returns :persona' do
      expect(described_class::PROVIDER).to eql(:persona)
    end
  end

  describe '#name' do
    it 'returns the full name of the user' do
      expect(school_persona.name).to eql(name)
    end
  end

  describe '#school_urn' do
    it 'returns the urn of the school of the user' do
      expect(school_persona.school_urn).to eql(school_urn)
    end
  end

  describe '#appropriate_body_user?' do
    it 'returns false' do
      expect(school_persona).not_to be_appropriate_body_user
    end
  end

  describe '#dfe_user?' do
    it 'returns false' do
      expect(school_persona).not_to be_dfe_user
    end
  end

  describe '#school_user?' do
    it 'returns true' do
      expect(school_persona).to be_school_user
    end
  end

  describe '#dfe_sign_in_authorisable?' do
    it 'returns false' do
      expect(school_persona.dfe_sign_in_authorisable?).to be_falsey
    end
  end

  describe '#to_h' do
    it 'returns a hash including only relevant attributes' do
      expect(school_persona.to_h).to eql({
                                           'type' => 'Sessions::Users::SchoolPersona',
                                           'email' => email,
                                           'name' => name,
                                           'last_active_at' => last_active_at,
                                           'school_urn' => school_urn
                                         })
    end
  end
end
