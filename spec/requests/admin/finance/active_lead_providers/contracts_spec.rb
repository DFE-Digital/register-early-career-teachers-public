RSpec.describe "Admin finance active lead provider contracts", type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
  let!(:contract) { FactoryBot.create(:contract, :for_ecf, framework_agreement:) }

  let(:contract_path) { admin_contract_period_active_lead_provider_contract_path(contract_period, framework_agreement, contract) }
  let(:contracts_path) { admin_contract_period_active_lead_provider_contracts_path(contract_period, framework_agreement) }
  let(:new_path) { new_admin_contract_period_active_lead_provider_contract_path(contract_period, framework_agreement) }
  let(:edit_path) { edit_admin_contract_period_active_lead_provider_contract_path(contract_period, framework_agreement, contract) }
  let(:delete_path) { delete_admin_contract_period_active_lead_provider_contract_path(contract_period, framework_agreement, contract) }

  describe "GET .../contracts" do
    it "redirects to sign in path when not signed in" do
      get contracts_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get contracts_path
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "returns success" do
        get contracts_path
        expect(response.status).to eq(200)
      end
    end
  end

  describe "GET .../contracts/:id" do
    it "redirects to sign in path when not signed in" do
      get contract_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get contract_path
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "returns success" do
        get contract_path
        expect(response.status).to eq(200)
      end
    end
  end

  describe "POST .../contracts" do
    let(:contract_period) { FactoryBot.create(:contract_period, :next) }
    let(:framework_agreement) do
      FactoryBot.create(:framework_agreement,
                        contract_period:)
    end
    let!(:alp_bands) do
      FactoryBot.create_list(:framework_agreement_band, 3,
                             framework_agreement:)
    end

    let(:flat_rate_fee_structure_attributes) do
      {
        recruitment_target: "100",
        fee_per_declaration: "500",
      }
    end

    let(:banded_fee_structure_attributes) do
      {
        recruitment_target: "100",
        uplift_fee_per_declaration: "50",
        setup_fee: "1000",
        band_terms_attributes: {
          "0" => {
            band_id: alp_bands[0].id,
            output_fee_percentage: "80",
            fee_per_declaration: "100"
          },
          "1" => {
            band_id: alp_bands[1].id,
            output_fee_percentage: "80",
            fee_per_declaration: "100"
          },
          "2" => {
            band_id: alp_bands[2].id,
            output_fee_percentage: "80",
            fee_per_declaration: "100"
          },
        },
      }
    end
    let(:contract_params) do
      {
        contract: {
          contract_type: "ittecf_ectp",
          vat_rate: "0.2",
          flat_rate_fee_structure_attributes:,
          banded_fee_structure_attributes:
        },
      }
    end

    it "redirects to sign in path when not signed in" do
      post contracts_path, params: contract_params
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        post contracts_path, params: contract_params
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "creates the contract and its band terms" do
        expect { post contracts_path, params: contract_params }.to change(Contract, :count).by(1)

        created_contract = Contract.last
        expect(response).to redirect_to(admin_contract_period_active_lead_provider_contract_path(contract_period, framework_agreement, created_contract))
        expect(created_contract.banded_fee_structure.band_terms.size).to eq(3)
        expect(created_contract.banded_fee_structure.band_terms.map(&:service_fee_ratio)).to all(eq(0.2))
        expect(created_contract.flat_rate_fee_structure.fee_per_declaration).to eq(500)
        expect(created_contract.flat_rate_fee_structure.recruitment_target).to eq(100)
      end

      context "and the submission omits flat-rate attributes" do
        let(:flat_rate_fee_structure_attributes) do
          {
            recruitment_target: "",
            fee_per_declaration: "",
          }
        end

        it "still renders flat-rate fields" do
          post contracts_path, params: contract_params

          expect(response.status).to eq(422)
          expect(response.body).to include("contract[flat_rate_fee_structure_attributes][recruitment_target]")
          expect(response.body).to include("contract[flat_rate_fee_structure_attributes][fee_per_declaration]")
        end
      end

      context "when editing the current contract period" do
        around do |example|
          travel_to(1.day.after(contract_period.started_on)) { example.run }
        end

        it "allows creating a new contract" do
          expect { post contracts_path, params: contract_params }.to change(Contract, :count).by(1)

          created_contract = Contract.last
          expect(response).to redirect_to(admin_contract_period_active_lead_provider_contract_path(contract_period, framework_agreement, created_contract))
        end
      end

      context "when editing a past contract period" do
        let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

        around do |example|
          travel_to(1.day.after(contract_period.finished_on)) { example.run }
        end

        it "allows creating a new contract" do
          expect { post contracts_path, params: contract_params }.to change(Contract, :count).by(1)

          created_contract = Contract.last
          expect(response).to redirect_to(admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider, created_contract))
        end
      end

      context "when editing a frozen contract period" do
        let(:contract_period) { FactoryBot.create(:contract_period, :previous, payments_frozen_at: 1.week.ago) }

        around do |example|
          travel_to(1.day.after(contract_period.payments_frozen_at)) { example.run }
        end

        it "blocks creating a new contract" do
          expect { post contracts_path, params: contract_params }.not_to change(Contract, :count)
          expect(response).to redirect_to(contracts_path)
          expect(flash[:error]).to eq("Contracts cannot be changed once payments have been frozen for the contract period")
        end
      end
    end
  end

  describe "GET .../contracts/:id/edit" do
    let(:contract_period) { FactoryBot.create(:contract_period, :next) }
    let!(:contract) do
      FactoryBot.create(:contract, :for_ittecf_ectp,
                        :with_bands_and_band_terms, framework_agreement:)
    end

    it "redirects to sign in path when not signed in" do
      get edit_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get edit_path
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "renders a hidden id for each persisted band term so they are updated rather than recreated" do
        get edit_path

        expect(response.status).to eq(200)

        contract.banded_fee_structure.band_terms.each_with_index do |band_term, index|
          expect(response.body).to include(
            %(value="#{band_term.id}" name="contract[banded_fee_structure_attributes][band_terms_attributes][#{index}][id]")
          )
        end
      end
    end

    context "when editing the current contract period" do
      include_context "sign in as finance DfE user"

      around do |example|
        travel_to(1.day.after(contract_period.started_on)) { example.run }
      end

      it "renders the edit page" do
        get edit_path

        expect(response.status).to eq(200)
      end
    end

    context "when editing a past contract period" do
      include_context "sign in as finance DfE user"

      let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

      around do |example|
        travel_to(1.day.after(contract_period.finished_on)) { example.run }
      end

      it "renders the edit page" do
        get edit_path

        expect(response.status).to eq(200)
      end
    end

    context "when editing a frozen contract period" do
      include_context "sign in as finance DfE user"

      let(:contract_period) { FactoryBot.create(:contract_period, :previous, payments_frozen_at: 1.week.ago) }

      around do |example|
        travel_to(1.day.after(contract_period.payments_frozen_at)) { example.run }
      end

      it "blocks editing a contract" do
        get edit_path
        expect(response).to redirect_to(contracts_path)
        expect(flash[:error]).to eq("Contracts cannot be changed once payments have been frozen for the contract period")
      end
    end
  end

  describe "PATCH .../contracts/:id" do
    let(:contract_period) { FactoryBot.create(:contract_period, :next) }
    let(:framework_agreement) do
      FactoryBot.create(:framework_agreement,
                        contract_period:)
    end
    let!(:contract) do
      FactoryBot.create(:contract, :for_ittecf_ectp,
                        :with_bands_and_band_terms, framework_agreement:)
    end
    let(:band_term) { contract.banded_fee_structure.band_terms.first }

    let(:update_params) do
      {
        contract: {
          vat_rate: 0.1,
          banded_fee_structure_attributes: {
            id: contract.banded_fee_structure.id,
            band_terms_attributes: {
              "0" => {
                id: band_term.id,
                band_id: band_term.band_id,
                fee_per_declaration: "999",
                output_fee_percentage: "80",
              },
            },
          },
        },
      }
    end

    it "redirects to sign in path when not signed in" do
      patch contract_path, params: update_params
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        patch contract_path, params: update_params
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      context "when editing the current contract period" do
        around do |example|
          travel_to(1.day.after(contract_period.started_on)) { example.run }
        end

        it "updates the contract and its band terms" do
          patch contract_path, params: update_params

          expect(response).to redirect_to(contract_path)
          expect(contract.reload.vat_rate).to eq(0.1)
          expect(band_term.reload.fee_per_declaration).to eq(999)
          expect(band_term.output_fee_ratio).to eq(0.8)
          expect(band_term.service_fee_ratio).to eq(0.2)
        end
      end

      context "when editing a past contract period" do
        let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

        around do |example|
          travel_to(1.day.after(contract_period.finished_on)) { example.run }
        end

        it "updates the contract and its band terms" do
          patch contract_path, params: update_params

          expect(response).to redirect_to(contract_path)
          expect(contract.reload.vat_rate).to eq(0.1)
          expect(band_term.reload.fee_per_declaration).to eq(999)
        end
      end

      context "when editing a frozen contract period" do
        let(:contract_period) { FactoryBot.create(:contract_period, :previous, payments_frozen_at: 1.week.ago) }

        around do |example|
          travel_to(1.day.after(contract_period.payments_frozen_at)) { example.run }
        end

        it "blocks editing a contract" do
          patch contract_path, params: update_params
          expect(response).to redirect_to(contracts_path)
          expect(flash[:error]).to eq("Contracts cannot be changed once payments have been frozen for the contract period")
        end
      end
    end
  end

  describe "DELETE .../contracts/:id" do
    let!(:contract_period) { FactoryBot.create(:contract_period, :next) }

    let!(:contract) do
      FactoryBot.create(:contract, :for_ittecf_ectp, :with_bands_and_band_terms,
                        framework_agreement:)
    end

    it "redirects to sign in path when not signed in" do
      delete contract_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        delete contract_path
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      context "when the contract has statements" do
        before { FactoryBot.create(:statement, contract:, framework_agreement:) }

        it "redirects back with an error and does not delete the contract" do
          expect { delete contract_path }.not_to change(Contract, :count)
          expect(response).to redirect_to(contract_path)
          expect(flash[:error]).to eq("Cannot delete a contract that has statements")
        end
      end

      context "when the contract has no statements" do
        context "when deleting in the current contract period" do
          around do |example|
            travel_to(1.day.after(contract_period.started_on)) { example.run }
          end

          it "allows deleting a contract" do
            expect { delete contract_path }.to change(Contract, :count).by(-1)
            expect(response).to redirect_to(contracts_path)
            expect(flash[:notice]).to eq("Contract deleted")
          end
        end

        context "when deleting in a past contract period" do
          let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

          around do |example|
            travel_to(1.day.after(contract_period.finished_on)) { example.run }
          end

          it "allows deleting a contract" do
            expect { delete contract_path }.to change(Contract, :count).by(-1)
            expect(response).to redirect_to(contracts_path)
            expect(flash[:notice]).to eq("Contract deleted")
          end
        end

        context "when deleting from a frozen contract period" do
          let(:contract_period) { FactoryBot.create(:contract_period, :previous, payments_frozen_at: 1.week.ago) }

          around do |example|
            travel_to(1.day.after(contract_period.payments_frozen_at)) { example.run }
          end

          it "redirects back with an error and does not delete the contract" do
            expect { delete contract_path }.not_to change(Contract, :count)
            expect(response).to redirect_to(contracts_path)
            expect(flash[:error]).to eq("Contracts cannot be changed once payments have been frozen for the contract period")
          end
        end
      end
    end
  end
end
