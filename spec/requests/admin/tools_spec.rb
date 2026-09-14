RSpec.describe "Admin::ToolsController" do
  describe "GET #show" do
    subject do
      get admin_tools_path
      response
    end

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

      before do
        allow(Rails.application.config).to receive_messages(
          enable_admin_data_fixes:,
          enable_blazer:
        )
      end

      let(:enable_admin_data_fixes) { true }
      let(:enable_blazer) { true }

      it { is_expected.to have_http_status(:ok) }

      it "links to the tools" do
        expect(subject.body).to include(
          %(href="/admin/data_fixes/csv"),
          %(href="/admin/blazer"),
          %(href="/admin/jobs")
        )
      end

      context "when data fixes are disabled" do
        let(:enable_admin_data_fixes) { false }

        it "does not link to data fixes" do
          expect(subject.body).not_to include(%(href="/admin/data_fixes/csv"))
        end
      end

      context "when Blazer is disabled" do
        let(:enable_blazer) { false }

        it "does not link to Blazer" do
          expect(subject.body).not_to include(%(href="/admin/blazer"))
        end
      end
    end
  end
end
