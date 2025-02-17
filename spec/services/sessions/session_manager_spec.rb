RSpec.describe Sessions::Manager do
  let(:session) { HashWithIndifferentAccess.new }
  let(:cookies) { HashWithIndifferentAccess.new }
  let(:email) { 'school_persona@email.com' }
  let(:name) { 'Christopher Lee' }
  let(:school_urn) { FactoryBot.create(:school).urn }
  let(:last_active_at) { 4.minutes.ago }
  let(:user) do
    Sessions::Users::SchoolUser.new(email:,
                                    name:,
                                    school_urn:,
                                    dfe_sign_in_organisation_id: '1',
                                    dfe_sign_in_user_id: '1',
                                    last_active_at:)
  end

  subject(:service) { Sessions::Manager.new(session, cookies) }

  before do
    allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_code: 'registerECTsAccess'))
  end

  describe '#begin_session!' do
    it 'creates a user_session hash in the session' do
      service.begin_session!(user)
      expect(session['user_session']).to be_present
    end

    it 'stores the user relevant attributes in the session' do
      service.begin_session!(user)

      expect(session['user_session']['type']).to eql('Sessions::Users::SchoolUser')
      expect(session['user_session']['email']).to eql(email)
      expect(session['user_session']['name']).to eql(name)
      expect(session['user_session']['school_urn']).to eql(school_urn)
      expect(session['user_session']['last_active_at']).to be_within(1.second).of(last_active_at)
      expect(session['user_session']['dfe_sign_in_organisation_id']).to eql('1')
      expect(session['user_session']['dfe_sign_in_user_id']).to eql('1')
    end

    it "'stores the id_token encrypted in the 'id_token' cookie'" do
      service.begin_session!(user, id_token: 'dfe_token')
      expect(cookies['id_token']).to be_present
    end

    context "when the user signs via DfE Sign In but has no 'registerECTsAccess' permissions for their organisation" do
      before { allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_code: 'somethingElse')) }

      it 'raises an MissingAccessLevel error' do
        expect { service.begin_session!(user) }.to raise_error(described_class::MissingAccessLevel)
      end
    end
  end

  describe '#current_user' do
    context 'when the session began' do
      before do
        service.begin_session!(user)
      end

      it 'is kind of a Sessions::User' do
        expect(service.current_user).to be_a(Sessions::User)
      end

      it 'returns the user associated with the session data' do
        expect(service.current_user.name).to eql(user.name)
      end

      it 'updates the last_active_at timestamp in both, the user and the user session' do
        expect(session['user_session']['last_active_at']).to be_within(1.second).of(last_active_at)

        new_user = service.current_user

        expect(session['user_session']['last_active_at']).to be_within(1.second).of(Time.zone.now)
        expect(new_user.last_active_at).to be_within(1.second).of(Time.zone.now)
      end
    end
  end

  describe '#end_session!' do
    let(:session) { double('Session', destroy: nil) }
    let(:cookies) { double('Cookies', delete: nil) }

    before { service.end_session! }

    it 'calls destroy on the session object' do
      expect(session).to have_received(:destroy).once
    end

    it "'calls delete on the cookies jar object with param 'id_token'" do
      expect(cookies).to have_received(:delete).with('id_token').once
    end
  end

  describe '#requested_path=' do
    let(:url) { 'https://path.to/something/' }

    it 'stores the requested path in the session' do
      service.requested_path = url
      expect(session['requested_path']).to eq url
    end
  end

  describe '#requested_path' do
    let(:url) { 'https://path.to/something/' }

    before do
      session['requested_path'] = url
    end

    it 'returns the requested path from the session' do
      expect(service.requested_path).to eq url
    end

    it 'removes the requested path from the session' do
      service.requested_path
      expect(session.keys.map(&:to_s)).not_to include 'requested_path'
    end
  end
end
