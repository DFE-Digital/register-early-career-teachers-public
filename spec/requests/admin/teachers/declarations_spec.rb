RSpec.describe "Admin::Teachers::DeclarationsController", type: :request do
  subject do
    get admin_teacher_declarations_path(teacher)
    response
  end

  let(:teacher) { FactoryBot.create(:teacher) }

  describe "GET /admin/teachers/:teacher_id/declarations" do
    context "when not signed in" do
      it { is_expected.to redirect_to(sign_in_path) }
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      it { is_expected.to have_http_status(:success) }
    end
  end
end
