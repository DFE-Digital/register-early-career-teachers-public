RSpec.describe "Appropriate Body bulk claims show page", type: :request do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim,
                      appropriate_body:,
                      data:)
  end

  include_context '2 valid claims'

  describe 'GET /appropriate-body/bulk/claims/:batch_id' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/bulk/claims/#{batch.id}")
        expect(response).to redirect_to(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      it 'renders the page successfully' do
        sign_in_as(:appropriate_body_user, appropriate_body:)
        get("/appropriate-body/bulk/claims/#{batch.id}")
        expect(response).to be_successful
      end
    end
  end
end
