RSpec.describe "Appropriate Body bulk actions show page", type: :request do
  include AuthHelper
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :action,
                      appropriate_body:,
                      data:)
  end

  include_context '3 valid actions'

  describe 'GET /appropriate-body/bulk/actions/:batch_id' do
    context 'when bulk upload is disabled (ENABLE_BULK_UPLOAD=false)' do
      before { allow(Rails.application.config).to receive(:enable_bulk_upload).and_return(false) }

      it 'is not found' do
        get("/appropriate-body/bulk/actions/#{batch.id}")
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/bulk/actions/#{batch.id}")
        expect(response).to be_redirection
        expect(response.redirect_url).to eql(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      it 'renders the page successfully' do
        sign_in_as(:appropriate_body_user, appropriate_body:)
        get("/appropriate-body/bulk/actions/#{batch.id}")
        expect(response).to be_successful
      end
    end
  end
end
