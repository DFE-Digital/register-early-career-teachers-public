require_relative 'session_user_context'

RSpec.describe Sessions::SchoolUser do
  let(:email) { 'school_user@email.com' }
  let(:name) { 'Christopher Lee' }
  let(:school_urn) { FactoryBot.create(:school).urn }
  let(:dfe_sign_in_organisation_id) { Faker::Internet.uuid }
  let(:last_active_at) { 4.minutes.ago }

  subject(:school_user) { described_class.new(email:, name:, school_urn:, dfe_sign_in_organisation_id:, last_active_at:) }

  it_behaves_like 'a session user' do
    let(:user_props) { { email:, name:, school_urn:, dfe_sign_in_organisation_id: } }
  end

  describe '.PROVIDER' do
    it 'returns :dfe_sign_in' do
      expect(described_class::PROVIDER).to eql(:dfe_sign_in)
    end
  end

  describe '#name' do
    it 'returns the full name of the user' do
      expect(school_user.name).to eql(name)
    end
  end

  describe '#school_urn' do
    it 'returns the urn of the school of the user' do
      expect(school_user.school_urn).to eql(school_urn)
    end
  end

  describe '#dfe_sign_in_organisation_id' do
    it 'returns the dfe_sign_in_organisation_id of the user' do
      expect(school_user.dfe_sign_in_organisation_id).to eql(dfe_sign_in_organisation_id)
    end
  end

  describe '#appropriate_body_user?' do
    it 'returns false' do
      expect(school_user).not_to be_appropriate_body_user
    end
  end

  describe '#dfe_user?' do
    it 'returns false' do
      expect(school_user).not_to be_dfe_user
    end
  end

  describe '#school_user?' do
    it 'returns true' do
      expect(school_user).to be_school_user
    end
  end

  describe '#to_h' do
    it 'returns a hash including only relevant attributes' do
      expect(school_user.to_h).to eql({
        'type' => 'Sessions::SchoolUser',
        'email' => email,
        'name' => name,
        'last_active_at' => last_active_at,
        'school_urn' => school_urn,
        'dfe_sign_in_organisation_id' => dfe_sign_in_organisation_id
      })
    end
  end
end
