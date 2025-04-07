RSpec.describe "Appropriate Body bulk claims show page", type: :request do
  include AuthHelper
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:batch) { FactoryBot.create(:pending_induction_submission_batch, :claim, appropriate_body:) }

  context 'when not signed in' do
    it 'redirects to the root page' do
      get("/appropriate-body/bulk/claims/#{batch.id}")
      expect(response).to be_redirection
      expect(response.redirect_url).to eql(root_url)
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
