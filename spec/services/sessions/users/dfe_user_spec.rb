require_relative 'session_user_context'

RSpec.describe Sessions::Users::DfEUser do
  let(:email) { 'dfe_user@email.com' }
  let(:name) { 'Christopher Lee' }
  let(:last_active_at) { 4.minutes.ago }
  let!(:user) { FactoryBot.create(:user, :admin, email:, name:) }

  subject(:dfe_user) { described_class.new(email:, last_active_at:) }

  it_behaves_like 'a session user' do
    let(:user_props) { { email: } }
  end

  describe '.PROVIDER' do
    it 'returns :otp' do
      expect(described_class::PROVIDER).to eql(:otp)
    end
  end

  describe '.EVENT_AUTHOR_TYPE' do
    it 'returns :dfe_staff_user' do
      expect(described_class::EVENT_AUTHOR_TYPE).to eql(:dfe_staff_user)
    end
  end

  describe '#name' do
    it 'returns the full name from the user record' do
      expect(dfe_user.name).to eql(name)
    end
  end

  describe '#appropriate_body_user?' do
    it 'returns false' do
      expect(dfe_user).not_to be_appropriate_body_user
    end
  end

  describe '#dfe_user?' do
    it 'returns true' do
      expect(dfe_user).to be_dfe_user
    end
  end

  describe '#school_user?' do
    it 'returns false' do
      expect(dfe_user).not_to be_school_user
    end
  end

  describe '#dfe_sign_in_authorisable?' do
    it 'returns false' do
      expect(dfe_user.dfe_sign_in_authorisable?).to be_falsey
    end
  end

  describe '#to_h' do
    it 'returns a hash including only relevant attributes' do
      expect(dfe_user.to_h).to eql({
        'type' => 'Sessions::Users::DfEUser',
        'email' => email,
        'last_active_at' => last_active_at
      })
    end
  end

  describe '#event_author_params' do
    it 'returns a hash with the attributes needed to record an event' do
      expect(dfe_user.event_author_params).to eql({
        author_email: dfe_user.email,
        author_id: dfe_user.id,
        author_name: dfe_user.name,
        author_type: :dfe_staff_user
      })
    end
  end
end
