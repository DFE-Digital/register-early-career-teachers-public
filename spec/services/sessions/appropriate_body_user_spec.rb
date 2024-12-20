require_relative 'session_user_context'

RSpec.describe Sessions::AppropriateBodyUser do
  let(:email) { 'appropriate_body_user@email.com' }
  let(:name) { 'Christopher Lee' }
  let(:dfe_sign_in_organisation_id) { Faker::Internet.uuid }
  let(:dfe_sign_in_user_id) { Faker::Internet.uuid }
  let(:last_active_at) { 4.minutes.ago }
  let!(:appropriate_body) { FactoryBot.create(:appropriate_body, dfe_sign_in_organisation_id:) }

  subject(:appropriate_body_user) do
    described_class.new(email:, name:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id:, last_active_at:)
  end

  it_behaves_like 'a session user' do
    let(:user_props) { { email:, name:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id: } }
  end

  describe '.PROVIDER' do
    it 'returns :dfe_sign_in' do
      expect(described_class::PROVIDER).to eql(:dfe_sign_in)
    end
  end

  describe '#appropriate_body_id' do
    it 'returns the id of the appropriate body of the user' do
      expect(appropriate_body_user.appropriate_body_id).to eql(appropriate_body.id)
    end
  end

  describe '#name' do
    it 'returns the full name of the appropriate body user' do
      expect(appropriate_body_user.name).to eql(name)
    end
  end

  describe '#dfe_sign_in_organisation_id' do
    it 'returns the id of the organisation of the user in DfE SignIn' do
      expect(appropriate_body_user.dfe_sign_in_organisation_id).to eql(dfe_sign_in_organisation_id)
    end
  end

  describe '#dfe_sign_in_user_id' do
    it 'returns the id of the user in DfE SignIn' do
      expect(appropriate_body_user.dfe_sign_in_organisation_id).to eql(dfe_sign_in_organisation_id)
    end
  end

  describe '#appropriate_body_user?' do
    it 'returns true' do
      expect(appropriate_body_user).to be_appropriate_body_user
    end
  end

  describe '#dfe_user?' do
    it 'returns false' do
      expect(appropriate_body_user).not_to be_dfe_user
    end
  end

  describe '#school_user?' do
    it 'returns false' do
      expect(appropriate_body_user).not_to be_school_user
    end
  end

  describe '#dfe_sign_in_authorisable?' do
    it 'returns true' do
      expect(appropriate_body_user.dfe_sign_in_authorisable?).to be_truthy
    end
  end

  describe '#to_h' do
    it 'returns a hash including only relevant attributes' do
      expect(appropriate_body_user.to_h).to eql({
        'type' => 'Sessions::AppropriateBodyUser',
        'email' => email,
        'name' => name,
        'last_active_at' => last_active_at,
        'dfe_sign_in_organisation_id' => dfe_sign_in_organisation_id,
        'dfe_sign_in_user_id' => dfe_sign_in_user_id
      })
    end
  end
end
