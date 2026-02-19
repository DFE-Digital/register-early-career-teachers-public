RSpec.describe "Admin finance statement authorisations", type: :request do
  let!(:statement) { FactoryBot.create(:statement) }
  let(:service) { double(authorise!: true) }

  before do
    allow(Statements::AuthorisePayment).to receive(:new).and_return(service)
  end

  describe "GET /admin/finance/statements/:statement_id/authorisations/new" do
    subject do
      get "/admin/finance/statements/#{statement.id}/authorisations/new"
      response
    end

    include_examples "requires finance access"

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      before { subject }

      it { is_expected.to have_http_status(:ok) }

      it "renders the confirmation form" do
        expect(subject.body).to include("Check and authorise statement for payment")
      end

      it "does not authorise the payment" do
        expect(service).not_to have_received(:authorise!)
      end
    end
  end

  describe "POST /admin/finance/statements/:statement_id/authorisations" do
    subject do
      post "/admin/finance/statements/#{statement.id}/authorisations",
           params: { admin_finance_authorise_payment_form: { confirmed: } }
      response
    end

    let(:confirmed) { "0" }

    include_examples "requires finance access"

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      before { subject }

      context "without confirmation" do
        it { is_expected.to have_http_status(:unprocessable_content) }

        it "renders the confirmation form with an error" do
          expect(subject.body).to include("You must have completed all assurance checks")
        end

        it "does not authorise the payment" do
          expect(service).not_to have_received(:authorise!)
        end
      end

      context "with confirmation" do
        let(:confirmed) { "1" }

        it { is_expected.to redirect_to(admin_finance_statement_path(statement)) }

        it "authorises the payment" do
          expect(service).to have_received(:authorise!)
        end

        it "flashes a success message" do
          expect(flash[:alert]).to eq "Statement authorised"
        end
      end
    end
  end
end
