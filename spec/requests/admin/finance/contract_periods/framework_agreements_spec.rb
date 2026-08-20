RSpec.describe "Admin framework agreements", type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:index_path) { admin_contract_period_framework_agreements_path(contract_period) }
  let(:started_error) { "Lead provider framework agreements cannot be changed once the contract period has started" }

  describe "GET /admin/contract-periods/:contract_period_id/framework-agreements" do
    it "redirects to sign in path when not signed in" do
      get index_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get index_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "displays the framework agreements index page" do
        get index_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /admin/contract-periods/:contract_period_id/framework-agreements/new" do
    let(:new_path) { new_admin_contract_period_framework_agreement_path(contract_period) }

    it "redirects to sign in path when not signed in" do
      get new_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get new_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "displays the new framework agreement page" do
        get new_path
        expect(response).to have_http_status(:success)
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "redirects to the index with an alert" do
          get new_path
          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq(started_error)
        end
      end
    end
  end

  describe "POST /admin/contract-periods/:contract_period_id/framework-agreements" do
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:params) { { framework_agreement: { lead_provider_id: lead_provider.id } } }

    it "redirects to sign in path when not signed in" do
      post(index_path, params:)
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        post(index_path, params:)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      let(:previous_contract_period) { FactoryBot.create(:contract_period, :current) }
      let(:previous_activation) { FactoryBot.create(:framework_agreement, contract_period: previous_contract_period, lead_provider:) }
      let(:previous_contract) { FactoryBot.create(:contract, :for_ittecf_ectp, framework_agreement: previous_activation) }
      let!(:previous_delivery_partnerships) do
        FactoryBot.create_list(:lead_provider_delivery_partnership, 2, framework_agreement: previous_activation)
      end

      let!(:previous_statement) do
        FactoryBot.create(:statement, :paid, framework_agreement: previous_activation, contract: previous_contract, month: 11, year: previous_contract_period.year)
      end

      it "creates a framework agreement seeded from the previous period, and redirects to the index" do
        expect { post index_path, params: }.to change(FrameworkAgreement, :count).by(1)

        framework_agreement = FrameworkAgreement.last
        expect(framework_agreement).to have_attributes(contract_period_year: contract_period.year, lead_provider_id: lead_provider.id)
        expect(framework_agreement.lead_provider_delivery_partnerships.map(&:delivery_partner))
          .to match_array(previous_activation.lead_provider_delivery_partnerships.map(&:delivery_partner))
        expect(framework_agreement.contracts.size).to eq(1)
        expect(framework_agreement.contracts.first.statements.map { |s| [s.month, s.year] })
          .to contain_exactly([11, contract_period.year])
        expect(response).to redirect_to(admin_contract_period_framework_agreements_path(contract_period))
      end

      context "when the lead provider is missing" do
        let(:params) { { framework_agreement: { lead_provider_id: "" } } }

        it "does not create a framework agreement and re-renders new" do
          expect { post index_path, params: }.not_to(change(FrameworkAgreement, :count))
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the lead provider already has a framework agreement for the contract period" do
        before { FactoryBot.create(:framework_agreement, contract_period:, lead_provider:) }

        it "does not create a duplicate and re-renders new" do
          expect { post index_path, params: }.not_to(change(FrameworkAgreement, :count))
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "does not create a framework agreement and redirects to the index with an alert" do
          expect { post index_path, params: }.not_to(change(FrameworkAgreement, :count))

          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq(started_error)
        end
      end
    end
  end

  describe "DELETE /admin/contract-periods/:contract_period_id/framework-agreements/:id" do
    let!(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
    let(:destroy_path) { admin_contract_period_framework_agreement_path(contract_period, framework_agreement) }

    it "redirects to sign in path when not signed in" do
      delete destroy_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        delete destroy_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "destroys the framework agreement and redirects to the index" do
        expect { delete destroy_path }.to change(FrameworkAgreement, :count).by(-1)

        expect(response).to redirect_to(admin_contract_period_framework_agreements_path(contract_period))
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "does not destroy the framework agreement and redirects to the index with an alert" do
          expect { delete destroy_path }.not_to(change(FrameworkAgreement, :count))

          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq(started_error)
        end
      end

      context "when the framework agreement has data that cannot be deleted" do
        before { FactoryBot.create(:training_period, :with_framework_agreement, framework_agreement:) }

        it "does not destroy the framework agreement and redirects to the index with an alert" do
          expect { delete destroy_path }.not_to(change(FrameworkAgreement, :count))

          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq("Cannot remove #{framework_agreement.lead_provider.name}: Training periods are present")
        end
      end
    end
  end

  describe "legacy active-lead-providers paths" do
    let(:legacy_root) { "/admin/finance/contract-periods/#{contract_period.year}/active-lead-providers" }

    it "permanently redirects the index and nested paths to their framework-agreements equivalents" do
      get legacy_root
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/admin/finance/contract-periods/#{contract_period.year}/framework-agreements")

      get "#{legacy_root}/123/bands"
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/admin/finance/contract-periods/#{contract_period.year}/framework-agreements/123/bands")
    end
  end
end
