RSpec.describe 'Admin::Schools', type: :request do
  let(:school) { FactoryBot.create(:school) }

  describe 'GET /admin/schools/:urn' do
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

      it 'redirects to overview page' do
        get admin_school_path(school.urn)
        expect(response).to redirect_to(overview_admin_school_path(school.urn))
      end

      it 'returns 404 when school not found' do
        get overview_admin_school_path('nonexistent')
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /admin/schools/:urn/overview' do
    context 'with an authenticated DfE user' do
      include_context 'sign in as DfE user'

      it 'returns successful response and renders the overview template' do
        get overview_admin_school_path(school.urn)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(school.name)
        expect(response.body).to include("URN: #{school.urn}")
      end

      it 'includes secondary navigation' do
        get overview_admin_school_path(school.urn)

        expect(response.body).to include('x-govuk-secondary-navigation')
        expect(response.body).to include('Overview')
        expect(response.body).to include('Teachers')
        expect(response.body).to include('Partnerships')
      end
    end
  end

  describe 'GET /admin/schools/:urn/teachers' do
    context 'with an authenticated DfE user' do
      include_context 'sign in as DfE user'

      it 'returns successful response and renders the teachers template' do
        get teachers_admin_school_path(school.urn)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(school.name)
        expect(response.body).to include("URN: #{school.urn}")
      end

      context 'when school has teachers' do
        let(:teacher) { FactoryBot.create(:teacher) }

        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, school:, teacher:)
        end

        it 'displays teachers in the teachers section' do
          get teachers_admin_school_path(school.urn)

          expect(response.body).to include('Teachers')
          expect(response.body).to include('ECT')
        end
      end
    end
  end

  describe 'GET /admin/schools/:urn/partnerships' do
    context 'with an authenticated DfE user' do
      include_context 'sign in as DfE user'

      it 'returns successful response and renders the partnerships template' do
        get partnerships_admin_school_path(school.urn)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(school.name)
        expect(response.body).to include("URN: #{school.urn}")
      end
    end
  end
end
