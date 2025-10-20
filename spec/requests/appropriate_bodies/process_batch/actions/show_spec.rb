RSpec.describe "Appropriate Body bulk actions show page", type: :request do
  include AuthHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :action,
      appropriate_body:,
      data:,
      file_name:)
  end

  include_context "3 valid actions"

  describe "GET /appropriate-body/bulk/actions/:batch_id" do
    context "when not signed in" do
      it "redirects to the root page" do
        get("/appropriate-body/bulk/actions/#{batch.id}")

        expect(response).to redirect_to(root_url)
      end
    end

    context "when signed in as an appropriate body user" do
      before do
        sign_in_as(:appropriate_body_user, appropriate_body:)
      end

      it "renders the page successfully" do
        get("/appropriate-body/bulk/actions/#{batch.id}")
        expect(response).to be_successful
      end

      it "can be rendered as a CSV download" do
        get("/appropriate-body/bulk/actions/#{batch.id}.csv")
        expect(response).to be_successful
        expect(response.headers["Content-Disposition"]).to include('filename="Errors for 3 valid actions.csv"')
        expect(response.body).to eq(
          <<~CSV_DATA
            "TRN","Date of birth","Induction period end date","Number of terms","Outcome","Error message"
          CSV_DATA
        )
      end
    end
  end
end
