RSpec.describe "Pages", type: :request do
  describe "GET /" do
    context 'when ENABLE_SCHOOLS_INTERFACE is true' do
      before do
        allow(Rails.application.config).to receive(:enable_schools_interface).and_return(true)
        get "/"
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end
    end

    context 'when ENABLE_SCHOOLS_INTERFACE is false' do
      before do
        allow(Rails.application.config).to receive(:enable_schools_interface).and_return(false)
        get "/"
      end

      it 'redirects to the appropriate body landing page' do
        expect(response).to redirect_to(ab_landing_path)
      end
    end
  end

  describe 'GET /access-denied' do
    context 'when a login attempt has succeeded' do
      before do
        get '/access-denied'
      end

      it 'redirects' do
        expect(response).to redirect_to(root_path)
      end
    end

    # rubocop:disable RSpec/AnyInstance
    context 'when a login attempt has failed' do
      before do
        allow_any_instance_of(PagesController).to receive(:session).and_return({
          invalid_user_organisation_name: 'Invalid Organisation'
        })

        get '/access-denied'
      end

      it 'shows the access denied page' do
        expect(response).to be_successful
        expect(response.body).to include('Invalid Organisation').and include('is not the correct organisation')
      end
    end
    # rubocop:enable RSpec/AnyInstance
  end

  describe 'GET /accessibility' do
    it 'shows the accessibility statement' do
      get '/accessibility'
      expect(response).to be_successful
      expect(response.body).to include('Accessibility statement')
    end
  end

  describe 'GET /privacy' do
    it 'shows the privacy policy' do
      get '/privacy'
      expect(response).to be_successful
      expect(response.body).to include('Privacy policy')
    end
  end

  describe 'GET /cookies' do
    it 'shows the cookies page' do
      get '/cookies'
      expect(response).to be_successful
      expect(response.body).to include('Cookies')
    end
  end

  describe 'GET /school-requirements' do
    it 'shows the school requirements page' do
      get '/school-requirements'
      expect(response).to be_successful
      expect(response.body).to include('What your school needs in place to register ECTs and mentors for ECTE')
    end
  end
end
