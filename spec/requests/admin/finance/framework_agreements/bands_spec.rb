RSpec.describe "Admin finance framework agreement bands", type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }

  let(:index_path) { admin_contract_period_framework_agreement_bands_path(contract_period, framework_agreement) }
  let(:new_path) { new_admin_contract_period_framework_agreement_band_path(contract_period, framework_agreement) }
  let(:edit_path) { edit_admin_contract_period_framework_agreement_band_path(contract_period, framework_agreement, band) }
  let(:band_path) { admin_contract_period_framework_agreement_band_path(contract_period, framework_agreement, band) }

  describe "GET .../bands" do
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

      it "returns success" do
        get index_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET .../bands/new" do
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

      it "returns success" do
        get new_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST .../bands" do
    it "redirects to sign in path when not signed in" do
      post index_path, params: { framework_agreement_band: { capacity: 500 } }
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        post index_path, params: { framework_agreement_band: { capacity: 500 } }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      let(:contract_period) { FactoryBot.create(:contract_period, :next) }

      it "creates a new band and redirects to the index" do
        expect {
          post index_path, params: { framework_agreement_band: { capacity: 500 } }
        }.to change(FrameworkAgreement::Band, :count).by(1)

        expect(response).to redirect_to(index_path)
        expect(flash[:notice]).to eq "Band A added"
      end

      context "when the params are invalid" do
        it "re-renders with an error status" do
          post index_path, params: { framework_agreement_band: { capacity: "eggs" } }

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the create, redirecting to the index" do
          expect {
            post index_path, params: { framework_agreement_band: { capacity: 500 } }
          }.not_to change(FrameworkAgreement::Band, :count)
          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq "Bands cannot be added or removed once contracts have been added or the contract period has started"
        end
      end
    end
  end

  describe "GET .../bands/:id/edit" do
    let!(:band) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }
    let(:edit_path) { edit_admin_contract_period_framework_agreement_band_path(contract_period, framework_agreement, band) }

    it "redirects to sign in path when not signed in" do
      get edit_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get edit_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "returns success" do
        get edit_path
        expect(response).to have_http_status(:ok)
      end

      context "when the band is not editable" do
        before do
          FactoryBot.create(:framework_agreement_band, framework_agreement:)
        end

        it "blocks the edit form, redirecting to the index" do
          get edit_path
          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq "Only the last band can be modified"
        end
      end
    end
  end

  describe "PATCH .../bands/:id" do
    let!(:band) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 500) }

    it "redirects to sign in path when not signed in" do
      patch band_path, params: { framework_agreement_band: { capacity: 750 } }
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        patch band_path, params: { framework_agreement_band: { capacity: 750 } }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "updates the band and redirects to the index" do
        patch band_path, params: { framework_agreement_band: { capacity: 750 } }

        expect(response).to redirect_to(index_path)
        expect(band.reload.capacity).to eq 750
      end

      context "when the params are invalid" do
        it "re-renders with an error status" do
          patch band_path, params: { framework_agreement_band: { capacity: 75 } }

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the band is not editable" do
        before do
          FactoryBot.create(:framework_agreement_band, framework_agreement:)
        end

        it "does not update the band and redirects to the index" do
          patch band_path, params: { framework_agreement_band: { capacity: 750 } }

          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq "Only the last band can be modified"
        end
      end
    end
  end

  describe "DELETE .../bands/:id" do
    let!(:band) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 500) }

    it "redirects to sign in path when not signed in" do
      delete band_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        delete band_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      let(:contract_period) { FactoryBot.create(:contract_period, :next) }

      it "destroys the statement and redirects to the index" do
        expect {
          delete band_path
        }.to change(FrameworkAgreement::Band, :count).by(-1)
        expect(response).to redirect_to(index_path)
        expect(flash[:notice]).to eq("Band #{band.letter} deleted")
      end

      context "when bands cannot be added or deleted" do
        let!(:contract) { FactoryBot.create(:contract, framework_agreement:) }

        it "does not delete the band and redirects to the index" do
          delete band_path
          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq("Bands cannot be added or removed once contracts have been added or the contract period has started")
        end
      end

      context "when the band is not deletable" do
        before do
          FactoryBot.create(:framework_agreement_band, framework_agreement:)
        end

        it "does not delete the band and redirects to the index" do
          delete band_path
          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq("Only the last band can be deleted")
        end
      end
    end
  end
end
