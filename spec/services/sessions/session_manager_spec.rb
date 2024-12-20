RSpec.describe Sessions::SessionManager do
  let(:session) { HashWithIndifferentAccess.new }
  let(:email) { 'school_persona@email.com' }
  let(:name) { 'Christopher Lee' }
  let(:school_urn) { FactoryBot.create(:school).urn }
  let(:last_active_at) { 4.minutes.ago }
  let(:user) { Sessions::SchoolPersona.new(email:, name:, school_urn:, last_active_at:) }

  subject(:service) { Sessions::SessionManager.new(session) }

  describe '#begin_session!' do
    it 'creates a user_session hash in the session' do
      service.begin_session!(user)
      expect(session['user_session']).to be_present
    end

    it 'stores the user relevant attributes in the session' do
      service.begin_session!(user)
      expect(session['user_session']['email']).to eql(user.email)
      expect(session['user_session']['name']).to eql(user.name)
      expect(session['user_session']['last_active_at']).to be_within(1.second).of(last_active_at)
    end
  end

  describe '#current_user' do
    context 'when the session began' do
      before do
        service.begin_session!(user)
      end

      it 'is kind of a Sessions::SessionUser' do
        expect(service.current_user).to be_a(Sessions::SessionUser)
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


    ###################
  describe "#begin_dfe_sign_in_session!" do
    let(:provider) { 'dfe_sign_in' }
    let(:first_name) { 'Milhouse' }
    let(:last_name) { 'Van Houten' }
    let(:email) { 'mvh@example.com' }

    before { allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new) }

    let(:user_info) do
      OmniAuth::AuthHash.new(
        {
          provider:,
          uid: email,
          info: { first_name:, last_name:, email: },
          extra: {
            raw_info: {
              organisation: {
                id: 1234
              }
            }
          }
        }
      )
    end

    it "creates a user_session hash in the session" do
      service.begin_dfe_sign_in_session!(user_info)

      expect(session["user_session"]).to be_present
    end

    context "when the DfE Sign-in API response doesn't have the 'registerECTsAccess' code" do
      before { allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new(role_code: 'somethingElse')) }

      it 'raises an MissingAccessLevel error' do
        expect { service.begin_dfe_sign_in_session!(user_info) }.to raise_error(Sessions::SessionManager::MissingAccessLevel)
      end
    end

    it "stores the email in the session" do
      service.begin_dfe_sign_in_session!(user_info)
      expect(session["user_session"]["email"]).to eq email
    end

    it "stores the provider in the session" do
      service.begin_dfe_sign_in_session!(user_info)
      expect(session["user_session"]["provider"]).to eq provider
    end

    it "stores a last active timestamp in the session" do
      service.begin_dfe_sign_in_session!(user_info)
      expect(session["user_session"]["last_active_at"]).to be_within(1.second).of(Time.zone.now)
    end
  end

  describe '#end_session!' do
    let(:session) { double('Session') }

    it 'calls destroy on the session object' do
      expect(session).to receive(:destroy).once
      service.end_session!
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
