require_relative 'session_user_context'

RSpec.describe Sessions::AppropriateBodyPersona do
  let(:email) { 'appropriate_body_persona@email.com' }
  let(:name) { 'Christopher Lee' }
  let(:appropriate_body_id) { FactoryBot.create(:appropriate_body).id }
  let(:last_active_at) { 4.minutes.ago }

  subject(:appropriate_body_persona) { described_class.new(email:, name:, appropriate_body_id:, last_active_at:) }

  it_behaves_like 'a session user' do
    let(:user_props) { { email:, name:, appropriate_body_id: } }
  end

  describe '.PROVIDER' do
    it 'returns :persona' do
      expect(described_class::PROVIDER).to eql(:persona)
    end
  end

  describe '#name' do
    it 'returns the name of the appropriate body persona' do
      expect(appropriate_body_persona.name).to eql(name)
    end
  end

  describe '#appropriate_body_id' do
    it 'returns the appropriate_body_id of the persona' do
      expect(appropriate_body_persona.appropriate_body_id).to eql(appropriate_body_id)
    end
  end

  describe '#appropriate_body_user?' do
    it 'returns true' do
      expect(appropriate_body_persona).to be_appropriate_body_user
    end
  end

  describe '#dfe_user?' do
    it 'returns false' do
      expect(appropriate_body_persona).not_to be_dfe_user
    end
  end

  describe '#school_user?' do
    it 'returns false' do
      expect(appropriate_body_persona).not_to be_school_user
    end
  end

  describe '#to_h' do
    it 'returns a hash including only relevant attributes' do
      expect(appropriate_body_persona.to_h).to eql({
        'type' => 'Sessions::AppropriateBodyPersona',
        'email' => email,
        'name' => name,
        'last_active_at' => last_active_at,
        'appropriate_body_id' => appropriate_body_id
      })
    end
  end
end
