RSpec.describe "Admin::DataFixesController" do
  describe "GET #new" do
    subject do
      get path_for_step("csv")
      response
    end

    before do
      allow(Rails.application.config)
        .to receive(:enable_admin_data_fixes)
        .and_return(enable_admin_data_fixes)
    end

    context "when `enable_admin_data_fixes` is true" do
      let(:enable_admin_data_fixes) { true }

      context "when not signed in" do
        it { is_expected.to redirect_to(sign_in_path) }
      end

      context "when signed in as a non-DfE user" do
        include_context "sign in as non-DfE user"

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context "when signed in as a non-product DfE user" do
        include_context "sign in as DfE user"

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context "when signed in as a product team user" do
        include_context "sign in as product_team DfE user"

        it { is_expected.to have_http_status(:ok) }
      end
    end

    context "when `enable_admin_data_fixes` is false" do
      let(:enable_admin_data_fixes) { false }

      context "when not signed in" do
        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a non-DfE user" do
        include_context "sign in as non-DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a non-product DfE user" do
        include_context "sign in as DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a product team user" do
        include_context "sign in as product_team DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end
    end
  end

  describe "POST #create" do
    subject do
      post(path_for_step("csv"), params:)
      response
    end

    let(:params) { { csv: { csv_string: } } }
    let(:csv_string) do
      <<~ROWS
        object_type,object_id,action,attributes
        something,1,create,"attribute1,value1,attribute2,value2"
        another_thing,2,destroy,""
      ROWS
    end

    before do
      allow(Rails.application.config)
        .to receive(:enable_admin_data_fixes)
        .and_return(enable_admin_data_fixes)
    end

    context "when `enable_admin_data_fixes` is true" do
      let(:enable_admin_data_fixes) { true }

      context "when not signed in" do
        it { is_expected.to redirect_to(sign_in_path) }
      end

      context "when signed in as a non-DfE user" do
        include_context "sign in as non-DfE user"

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context "when signed in as a non-product DfE user" do
        include_context "sign in as DfE user"

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context "when signed in as a product team user" do
        include_context "sign in as product_team DfE user"

        context "when the CSV is valid" do
          it { is_expected.to redirect_to(path_for_step("preview")) }
        end

        context "when the CSV is invalid" do
          let(:csv_string) do
            <<~ROWS
              object_type,object_id,attributes
              something,1,create,"attribute1,value1,attribute2,value2"
              another_thing,2,destroy,""
            ROWS
          end

          it { is_expected.to have_http_status(:unprocessable_content) }
        end
      end
    end

    context "when `enable_admin_data_fixes` is false" do
      let(:enable_admin_data_fixes) { false }

      context "when not signed in" do
        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a non-DfE user" do
        include_context "sign in as non-DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a non-product DfE user" do
        include_context "sign in as DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a product team user" do
        include_context "sign in as product_team DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end
    end
  end

private

  def path_for_step(step) = "/admin/data_fixes/#{step}"
end
