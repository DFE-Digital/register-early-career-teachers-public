RSpec.describe Sessions::SessionBuilder do
  describe '#build!' do
    let(:session_manager) { Sessions::SessionManager.new({}) }

    let(:name) { 'Barney Gumble' }
    let(:email) { 'bg@something.org' }

    context 'when the provider is developer' do
      let(:provider) { 'developer' }
      let(:user_info) { OmniAuth::AuthHash.new({ info: { name:, email: } }) }

      context 'when the user is dfe staff' do
        let(:params) { { 'dfe' => 'true' } }

        it 'calls begin_otp_session!' do
          allow(session_manager).to receive(:begin_otp_session!).and_return(true)
          Sessions::SessionBuilder.new(provider, session_manager:, user_info:, params:).build!
          expect(session_manager).to have_received(:begin_otp_session!).with(email)
        end
      end

      context 'when the user is dfe staff' do
        let(:school_urn) { '2222222' }
        let(:appropriate_body_id) { '3' }
        let(:params) { { 'school_urn' => school_urn, 'appropriate_body_id' => appropriate_body_id } }

        it 'calls begin_persona_session!' do
          allow(session_manager).to receive(:begin_persona_session!).and_return(true)
          Sessions::SessionBuilder.new(provider, session_manager:, user_info:, params:).build!
          expect(session_manager).to have_received(:begin_persona_session!).with(email, name:, appropriate_body_id:, school_urn:)
        end
      end
    end

    context 'when the provider is dfe_sign_in' do
      let(:provider) { 'dfe_sign_in' }
      let(:user_info) { OmniAuth::AuthHash.new({ info: { name:, email: } }) }

      context 'when the user is dfe staff' do
        let(:params) { { 'dfe' => 'true' } }

        it 'calls begin_dfe_sign_in_session!' do
          allow(session_manager).to receive(:begin_dfe_sign_in_session!).and_return(true)
          Sessions::SessionBuilder.new(provider, session_manager:, user_info:, params:).build!
          expect(session_manager).to have_received(:begin_dfe_sign_in_session!).with(user_info)
        end
      end
    end

    context 'when the provider is unknown' do
      let(:provider) { 'something_unexpected' }
      let(:params) { {} }
      let(:user_info) { {} }

      it 'raises an UnknownProvider error' do
        session_builder = Sessions::SessionBuilder.new(provider, session_manager:, user_info:, params:)

        expect { session_builder.build! }.to raise_error(Sessions::SessionBuilder::UnknownProvider, provider)
      end
    end
  end
end
