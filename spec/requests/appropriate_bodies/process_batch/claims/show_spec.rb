RSpec.describe "Appropriate Body bulk claims show page", type: :request do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim,
                      appropriate_body_period:,
                      data:)
  end

  include_context "2 valid claims"

  describe "GET /appropriate-body/bulk/claims/:batch_id" do
    context "when not signed in" do
      it "redirects to the root page" do
        get("/appropriate-body/bulk/claims/#{batch.id}")
        expect(response).to redirect_to(root_url)
      end
    end

    context "when signed in as an appropriate body user" do
      it "renders the page successfully" do
        sign_in_as(:appropriate_body_user, appropriate_body: appropriate_body_period)
        get("/appropriate-body/bulk/claims/#{batch.id}")
        expect(response).to be_successful
      end
    end
  end
end
