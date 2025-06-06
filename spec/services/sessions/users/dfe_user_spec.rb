require_relative 'session_user_context'

RSpec.describe Sessions::Users::DfEUser do
  subject(:dfe_user) { described_class.new(email:, last_active_at:) }

  let(:email) { 'dfe_user@email.com' }
  let(:name) { 'Christopher Lee' }
  let(:last_active_at) { 4.minutes.ago }
  let!(:user) { FactoryBot.create(:user, :admin, email:, name:) }

  it_behaves_like 'a session user' do
    let(:user_props) { { email: } }
  end

  describe '.PROVIDER' do
    it 'returns :otp' do
      expect(described_class::PROVIDER).to be(:otp)
    end
  end

  describe '.USER_TYPE' do
    it 'returns :dfe_staff_user' do
      expect(described_class::USER_TYPE).to be(:dfe_staff_user)
    end
  end

  context 'initialisation' do
    describe "when there is no user with the given email" do
      subject { described_class.new(email: unknown_email, last_active_at:) }

      let(:unknown_email) { Faker::Internet.email }

      it 'fails with an UnknownUserEmail error' do
        expect { subject }.to raise_error(described_class::UnknownUserEmail, unknown_email)
      end
    end

    describe "when there is a user with the given email lowercased" do
      subject { described_class.new(email: similar_email, last_active_at:) }

      let(:similar_email) { 'DfE_User@email.com' }

      it "instantiates Sessions::Users::DfEUser from the database user" do
        expect(subject).to be_a(described_class)
        expect(subject.email).to eq('dfe_user@email.com')
      end
    end
  end

  describe '#appropriate_body_user?' do
    it 'returns false' do
      expect(dfe_user).not_to be_appropriate_body_user
    end
  end

  describe '#dfe_sign_in_authorisable?' do
    it 'returns false' do
      expect(dfe_user.dfe_sign_in_authorisable?).to be_falsey
    end
  end

  describe '#dfe_user?' do
    it 'returns true' do
      expect(dfe_user).to be_dfe_user
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

  describe '#name' do
    it 'returns the full name from the user record' do
      expect(dfe_user.name).to eql(name)
    end
  end

  describe '#organisation_name' do
    it 'returns Department for Education' do
      expect(dfe_user.organisation_name).to eq('Department for Education')
    end
  end

  describe '#school_user?' do
    it 'returns false' do
      expect(dfe_user).not_to be_school_user
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

  describe '#user_type' do
    it('is :dfe_staff_user') { expect(dfe_user.user_type).to be(:dfe_staff_user) }
  end

  describe '#user' do
    it 'returns the User instance associated to this session user' do
      expect(dfe_user.user).to eq(user)
    end
  end
end
