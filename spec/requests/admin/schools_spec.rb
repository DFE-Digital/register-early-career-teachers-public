RSpec.describe 'Admin::Schools', type: :request do
  describe 'GET /admin/schools/:urn' do
    let(:school) { FactoryBot.create(:school) }

    it 'redirects to sign in path when not authenticated' do
      get admin_school_path(school.urn)
      expect(response).to redirect_to(sign_in_path)
    end

    context 'with an authenticated non-DfE user' do
      include_context 'sign in as non-DfE user'

      it 'requires authorisation' do
        get admin_school_path(school.urn)
        expect(response.status).to eq(401)
      end
    end

    context 'with an authenticated DfE user' do
      include_context 'sign in as DfE user'

      it 'returns successful response and renders the show template' do
        get admin_school_path(school.urn)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(school.name)
        expect(response.body).to include("URN: #{school.urn}")
      end

      it 'includes navigation list' do
        get admin_school_path(school.urn)

        expect(response.body).to include('Overview')
        expect(response.body).to include('Teachers')
        expect(response.body).to include('Partnerships')
      end

      it 'returns 404 when school not found' do
        get admin_school_path('nonexistent')
        expect(response).to have_http_status(:not_found)
      end

      context 'when school has teachers' do
        let(:teacher) { FactoryBot.create(:teacher) }

        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, school:, teacher:)
        end

        it 'displays teachers in the teachers section' do
          get admin_school_path(school.urn)

          expect(response.body).to include('Teachers')
          expect(response.body).to include('ECT')
        end
      end
    end
  end
end
