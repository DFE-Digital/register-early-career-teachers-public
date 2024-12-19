RSpec.describe 'Sessions' do
  let(:email) { 'moe@example.com' }
  let(:name) { 'Moe Szyslak' }
  let(:school_urn) { '1111111' }
  let(:appropriate_body_id) { '2' }
  let(:dfe_staff) { 'false' }

  describe 'GET /auth/developer/callback' do
    describe 'when signing in with the developer provider' do
      let(:provider) { 'developer' }

      let(:params) do
        {
          'email' => email,
          'name' => name,
          'appropriate_body_id' => appropriate_body_id,
          'school_urn' => school_urn,
          'dfe' => dfe_staff,
        }
      end

      context 'when dfe staff' do
        let(:dfe_staff) { 'true' }

        it 'calls Sessions::BuildSession.new with params including "dfe" => "true"' do
          allow(Sessions::SessionBuilder).to receive(:new).and_call_original

          post('/auth/developer/callback', params:)

          expect(Sessions::SessionBuilder).to have_received(:new).with(
            'developer',
            session_manager: instance_of(Sessions::SessionManager),
            params: hash_including(
              "dfe" => dfe_staff,
              "appropriate_body_id" => appropriate_body_id,
              "school_urn" => school_urn
            ),
            user_info: {
              "credentials" => {},
              "extra" => {},
              "info" => {
                "email" => email,
                "name" => name
              },
              "provider" => provider,
              "uid" => email
            }
          )
        end
      end

      context 'when not dfe staff' do
        let(:dfe_staff) { 'false' }

        it 'calls Sessions::BuildSession.new with params including "dfe" => "false"' do
          allow(Sessions::SessionBuilder).to receive(:new).and_call_original

          post('/auth/developer/callback', params:)

          expect(Sessions::SessionBuilder).to have_received(:new).with(
            'developer',
            session_manager: instance_of(Sessions::SessionManager),
            params: hash_including(
              "dfe" => dfe_staff,
              "appropriate_body_id" => appropriate_body_id,
              "school_urn" => school_urn
            ),
            user_info: {
              "credentials" => {},
              "extra" => {},
              "info" => {
                "email" => email,
                "name" => name
              },
              "provider" => provider,
              "uid" => email
            }
          )
        end
      end
    end
  end

  describe 'GET /auth/dfe/callback' do
    let(:uuid) { SecureRandom.uuid }

    let(:params) { { 'email' => email, 'name' => name } }

    before { allow_any_instance_of(Sessions::SessionManager).to receive(:begin_dfe_sign_in_session!).and_return(true) }

    it 'calls Sessions::BuildSession.new with the expected arguments' do
      OmniAuth.config.test_mode = true
      OmniAuth.config.add_mock(:dfe_sign_in, uid: uuid, info: { email:, name: })

      allow(Sessions::SessionBuilder).to receive(:new).and_call_original

      post('/auth/dfe/callback', params:)

      expect(Sessions::SessionBuilder).to have_received(:new).with(
        'dfe_sign_in',
        session_manager: instance_of(Sessions::SessionManager),
        params: instance_of(ActionController::Parameters),
        user_info: instance_of(OmniAuth::AuthHash)
      )
    ensure
      OmniAuth.config.test_mode = false
    end
  end
end
