RSpec.describe "Admin finance statements index", type: :request do
  describe "GET /admin/finance/statements" do
    it "redirects to sign in path" do
      get "/admin/finance/statements"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get "/admin/finance/statements"
        expect(response.status).to eq(401)
      end
    end

    context 'when signed in as a DfE user' do
      include_context 'sign in as DfE user'

      it 'displays the finance page' do
        get "/admin/finance/statements"

        expect(response.status).to eq(200)
      end

      it 'retrieves a list of statements' do
        allow(Statements::Query).to receive(:new).and_call_original

        get "/admin/finance/statements"

        expect(Statements::Query).to have_received(:new).once
      end
    end
  end

  describe "GET /admin/finance/statements/:statement_id" do
    it "redirects to sign in path" do
      get "/admin/finance/statements/1"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get "/admin/finance/statements/1"
        expect(response.status).to eq(401)
      end
    end

    context 'when signed in as a DfE user' do
      let!(:statement) { FactoryBot.create(:statement) }

      include_context 'sign in as DfE user'

      it 'displays the finance page' do
        get "/admin/finance/statements/#{statement.id}"

        expect(response.status).to eq(200)
      end

      it 'uses the presenter to display the statement' do
        allow(Admin::StatementPresenter).to receive(:new).with(statement).and_call_original

        get "/admin/finance/statements/#{statement.id}"

        expect(Admin::StatementPresenter).to have_received(:new).with(statement).once
      end
    end
  end
end
