RSpec.describe "Admin finance void declarations", type: :request do
  let(:declaration) { FactoryBot.create(:declaration) }

  shared_examples "requires finance access" do
    context "when not signed in" do
      it { is_expected.to redirect_to(sign_in_path) }
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it { is_expected.to have_http_status(:unauthorized) }

      it "renders the finance access error message" do
        expect(subject.body).to include(
          "This is to access financial information for Register early career teachers. To gain access, contact the product team."
        )
      end
    end
  end

  describe "GET /admin/finance/declarations/:id/voids/new" do
    subject do
      get "/admin/finance/declarations/#{declaration.id}/voids/new"
      response
    end

    include_examples "requires finance access"

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it { is_expected.to have_http_status(:ok) }

      it "renders the void confirmation page" do
        expect(subject.body).to include("Void declaration for")
      end
    end
  end

  describe "POST /admin/finance/void-declarations/:id" do
    subject do
      post "/admin/finance/declarations/#{declaration.id}/voids", params: { admin_finance_void_declaration_form: { confirmed: "1" } }
      response
    end

    include_examples "requires finance access"

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      let(:form) { Admin::Finance::VoidDeclarationForm.new(declaration:, author: user, confirmed: "1") }

      before do
        allow(Admin::Finance::VoidDeclarationForm).to receive(:new).and_return(form)
      end

      context "when the void is successful" do
        before { allow(form).to receive(:void!).and_return(true) }

        it { is_expected.to redirect_to(admin_teacher_declarations_path(declaration.teacher)) }

        it "sets a flash message" do
          subject
          expect(flash[:alert]).to eq("Declaration voided")
        end
      end

      context "when the void is not successful" do
        before { allow(form).to receive(:void!).and_return(false) }

        it { is_expected.to have_http_status(:unprocessable_content) }
      end
    end
  end
end
