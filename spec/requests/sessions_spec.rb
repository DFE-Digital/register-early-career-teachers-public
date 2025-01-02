RSpec.describe 'Sessions', type: :request do
  include ActionView::Helpers::SanitizeHelper

  describe 'GET /sign-in' do
    context 'when not signed in' do
      it 'renders the sign in page' do
        get('/sign-in')

        expect(response).to be_successful
        expect(sanitize(response.body)).to include('Select a sign in method')
      end
    end

    context 'when signed in' do
      before do
        school = FactoryBot.create(:school, urn: '123456')
        sign_in_as(:school_user, school:)
      end

      it 'renders the sign in page' do
        get('/sign-in')

        expect(response).to be_successful
        expect(sanitize(response.body)).to include('Select a sign in method')
      end
    end
  end

  describe 'POST /auth/:provider/callback' do
    let(:email) { Faker::Internet.email }
    let(:first_name) { Faker::Name.first_name }
    let(:last_name) { Faker::Name.last_name }
    let(:name) { [first_name, last_name].join(" ").strip }
    let(:dfe_sign_in_organisation_id) { Faker::Internet.uuid }
    let(:dfe_sign_in_user_id) { Faker::Internet.uuid }
    let(:school_urn) { '123456' }

    context 'sign in an appropriate body user' do
      let(:params) { { email:, name:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id: } }
      let!(:appropriate_body) { FactoryBot.create(:appropriate_body, dfe_sign_in_organisation_id:) }

      before do
        allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new)
        mock_dfe_sign_in_provider!(uid: dfe_sign_in_user_id,
                                   email:,
                                   first_name:,
                                   last_name:,
                                   organisation_id: dfe_sign_in_organisation_id)
      end

      after do
        stop_mocking_dfe_sign_in_provider!
      end

      it 'signs the user and take them to their home page' do
        allow(Sessions::Users::AppropriateBodyUser).to receive(:new).and_call_original

        post('/auth/dfe/callback')

        expect(Sessions::Users::AppropriateBodyUser).to have_received(:new).with(**params).once
        expect(response).to redirect_to(ab_teachers_path)
      end
    end

    context 'sign in a school user' do
      let(:params) { { email:, name:, school_urn:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id: } }
      let!(:school) { FactoryBot.create(:school, urn: school_urn) }

      before do
        allow(DfESignIn::APIClient).to receive(:new).and_return(DfESignIn::FakeAPIClient.new)
        mock_dfe_sign_in_provider!(uid: dfe_sign_in_user_id,
                                   email:,
                                   first_name:,
                                   last_name:,
                                   organisation_id: dfe_sign_in_organisation_id,
                                   organisation_urn: school_urn)
      end

      after do
        stop_mocking_dfe_sign_in_provider!
      end

      it 'signs the user and take them to their home page' do
        allow(Sessions::Users::SchoolUser).to receive(:new).and_call_original

        post('/auth/dfe/callback')

        expect(Sessions::Users::SchoolUser).to have_received(:new).with(**params).once
        expect(response).to redirect_to(schools_ects_home_path)
      end
    end

    context 'sign in an appropriate body persona' do
      let(:appropriate_body_id) { FactoryBot.create(:appropriate_body).id.to_s }
      let(:params) { { email:, name:, appropriate_body_id: } }

      it 'signs the user and take them to their home page' do
        allow(Sessions::Users::AppropriateBodyPersona).to receive(:new).and_call_original

        post('/auth/persona/callback', params:)

        expect(Sessions::Users::AppropriateBodyPersona).to have_received(:new).with(**params).once
        expect(response).to redirect_to(ab_teachers_path)
      end
    end

    context 'sign in a school persona' do
      let(:school_urn) { FactoryBot.create(:school).urn.to_s }
      let(:params) { { email:, name:, school_urn: } }

      it 'signs the user and take them to their home page' do
        allow(Sessions::Users::SchoolPersona).to receive(:new).and_call_original

        post('/auth/persona/callback', params:)

        expect(Sessions::Users::SchoolPersona).to have_received(:new).with(**params).once
        expect(response).to redirect_to(schools_ects_home_path)
      end
    end

    context 'sign in a dfe_persona' do
      before do
        FactoryBot.create(:user, email:, name:).dfe_roles.create!
      end

      it 'signs the user and take them to their home page' do
        allow(Sessions::Users::DfEPersona).to receive(:new).and_call_original

        post('/auth/persona/callback', params: { dfe_staff: true, email:, name: })

        expect(Sessions::Users::DfEPersona).to have_received(:new).with(email:).once
        expect(response).to redirect_to(admin_path)
      end
    end
  end

  describe 'GET /sign-out' do
    let(:session_manager) { double('Sessions::SessionManager', current_user: nil, end_session!: true) }

    context 'when not signed in' do
      it 'redirect to the sign in page' do
        allow(Sessions::SessionManager).to receive(:new).and_return(session_manager)

        get('/sign-out')

        expect(session_manager).to have_received(:end_session!).once
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
