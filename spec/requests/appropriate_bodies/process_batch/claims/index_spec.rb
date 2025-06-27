RSpec.describe "Appropriate Body bulk claims index page", type: :request do
  include AuthHelper
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe 'GET /appropriate-body/bulk/claims' do
    context 'when bulk upload and claim is disabled (ENABLE_BULK_UPLOAD=false, ENABLE_BULK_CLAIM=false)' do
      before do
        allow(Rails.application.config).to receive_messages(enable_bulk_upload: false, enable_bulk_claim: false)
      end

      it 'is not found' do
        get("/appropriate-body/bulk/claims")
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/bulk/claims")
        expect(response).to be_redirection
        expect(response.redirect_url).to eql(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      it 'renders the page successfully' do
        sign_in_as(:appropriate_body_user, appropriate_body:)
        get("/appropriate-body/bulk/claims")
        expect(response).to be_successful
      end
    end
  end
end
