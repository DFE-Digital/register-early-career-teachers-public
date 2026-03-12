RSpec.describe "Admin finance search declarations", type: :request do
  describe "GET /admin/finance/search-declarations" do
    it "redirects to sign in path" do
      get "/admin/finance/search-declarations"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/finance/search-declarations"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation with the finance access error message" do
        get "/admin/finance/search-declarations"

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include(
          "This is to access financial information for Register early career teachers. To gain access, contact the product team."
        )
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "displays the search page" do
        get "/admin/finance/search-declarations"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Search declarations")
      end

      context "when the search query is blank" do
        it "does not show results or errors" do
          get "/admin/finance/search-declarations", params: { declaration_api_id: "" }

          expect(response).to have_http_status(:ok)
          expect(response.body).not_to include("No results found")
        end
      end

      context "when no matching declaration exists" do
        it "shows 'No results found'" do
          get "/admin/finance/search-declarations", params: { declaration_api_id: "non-existent-id" }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("No results found")
        end
      end

      context "when a matching declaration exists" do
        let!(:declaration) do
          FactoryBot.create(:declaration)
        end

        it "redirects to the teacher declarations page" do
          get "/admin/finance/search-declarations", params: { declaration_api_id: declaration.api_id }

          teacher = declaration.ect_teacher || declaration.mentor_teacher

          expect(response).to redirect_to(
            admin_teacher_declarations_path(teacher, anchor: "declarations")
          )
        end
      end
    end
  end
end
