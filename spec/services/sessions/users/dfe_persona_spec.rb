RSpec.describe Sessions::Users::DfEPersona do
  subject(:dfe_persona) { described_class.new(email:, last_active_at:) }

  let!(:user) { FactoryBot.create(:user, :admin) }
  let(:email) { user.email }
  let(:last_active_at) { 4.minutes.ago }

  it_behaves_like 'a session user' do
    let(:user_props) { { email: } }
  end

  context 'when personas are disabled' do
    before { allow(Rails.application.config).to receive(:enable_personas).and_return(false) }

    it do
      expect { dfe_persona }.to raise_error(described_class::DfEPersonaDisabledError)
    end
  end

  context 'when there is no user with the given email' do
    let(:email) { Faker::Internet.email }

    it do
      expect { dfe_persona }.to raise_error(described_class::UnknownUserEmail, email)
    end
  end

  context "when a valid email is provided with a different case" do
    let(:email) { user.email.upcase }

    it "instantiates Sessions::Users::DfEPersona from the database user" do
      expect(dfe_persona).to be_a(described_class)
      expect(dfe_persona.email).to eq(user.email)
    end
  end

  describe '#provider' do
    it { expect(dfe_persona.provider).to be(:persona) }
  end

  describe '#user_type' do
    it { expect(dfe_persona.user_type).to be(:dfe_staff_user) }
  end

  describe '#appropriate_body_user?' do
    it { expect(dfe_persona).not_to be_appropriate_body_user }
  end

  describe '#dfe_user?' do
    it { expect(dfe_persona).to be_dfe_user }
  end

  describe '#event_author_params' do
    it 'returns a hash with the attributes needed to record an event' do
      expect(dfe_persona.event_author_params).to eql({
        author_email: user.email,
        author_id: user.id,
        author_name: user.name,
        author_type: :dfe_staff_user
      })
    end
  end

  describe '#name' do
    it 'returns the full name from the user record' do
      expect(dfe_persona.name).to eql(user.name)
    end
  end

  describe '#has_authorised_role?' do
    it { expect(dfe_persona).to have_authorised_role }
  end

  describe '#organisation_name' do
    it 'returns Department for Education' do
      expect(dfe_persona.organisation_name).to eq('Department for Education')
    end
  end

  describe '#school_user?' do
    it { expect(dfe_persona).not_to be_school_user }
  end

  describe '#to_h' do
    it 'returns attributes for session storage' do
      expect(dfe_persona.to_h).to eql({
        'type' => 'Sessions::Users::DfEPersona',
        'email' => email,
        'last_active_at' => last_active_at
      })
    end
  end

  describe '#user' do
    it 'returns the User instance associated to this session user' do
      expect(dfe_persona.user).to eq(user)
    end
  end
end
