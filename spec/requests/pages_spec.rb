RSpec.describe "Pages", type: :request do
  describe "GET /" do
    context 'when ENABLE_SCHOOLS_INTERFACE is true' do
      before { allow(Rails.application.config).to receive(:enable_schools_interface).and_return(true) }

      it "returns http success" do
        get "/"
        expect(response).to have_http_status(:success)
      end
    end

    context 'when ENABLE_SCHOOLS_INTERFACE is false' do
      before { allow(Rails.application.config).to receive(:enable_schools_interface).and_return(false) }

      it 'redirects to the appropriate body landing page' do
        get "/"
        expect(response).to redirect_to(ab_landing_path)
      end
    end
  end

  describe 'GET /accessibility' do
    it 'shows the accessibilty statement' do
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
