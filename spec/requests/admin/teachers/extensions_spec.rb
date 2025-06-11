RSpec.describe "Admin::Teachers::Extensions", type: :request do
  include AuthHelper

  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:teacher) { FactoryBot.create(:teacher) }

  before do
    sign_in_as :dfe_user, user: admin_user
  end

  describe "GET /admin/teachers/:teacher_id/extensions" do
    it "renders the index template successfully" do
      get admin_teacher_extensions_path(teacher)
      expect(response).to be_successful
    end
  end

  describe "GET /admin/teachers/:teacher_id/extensions/new" do
    it "renders the new template successfully" do
      get new_admin_teacher_extension_path(teacher)
      expect(response).to be_successful
    end
  end

  describe "POST /admin/teachers/:teacher_id/extensions" do
    context "with valid parameters" do
      let(:valid_params) { { induction_extension: { number_of_terms: 1.5 } } }

      it "creates a new extension and redirects to the teacher's page" do
        expect {
          post admin_teacher_extensions_path(teacher), params: valid_params
        }.to change(InductionExtension, :count).by(1)

        expect(response).to redirect_to(admin_teacher_path(teacher))
        expect(flash[:notice]).to eq("Extension was successfully added.")
      end
    end
  end

  describe "GET /admin/teachers/:teacher_id/extensions/:id/edit" do
    let(:extension) { FactoryBot.create(:induction_extension, teacher:) }

    it "renders the edit template successfully" do
      get edit_admin_teacher_extension_path(teacher, extension)
      expect(response).to be_successful
    end
  end

  describe "PATCH /admin/teachers/:teacher_id/extensions/:id" do
    let!(:extension) { FactoryBot.create(:induction_extension, teacher:, number_of_terms: 1.0) }

    context "with valid parameters" do
      let(:valid_params) { { induction_extension: { number_of_terms: 2.5 } } }

      it "updates the extension and redirects to the teacher's page" do
        patch admin_teacher_extension_path(teacher, extension), params: valid_params
        extension.reload
        expect(extension.number_of_terms).to eq(2.5)
        expect(response).to redirect_to(admin_teacher_path(teacher))
        expect(flash[:notice]).to eq("Extension was successfully updated.")
      end
    end
  end

  describe "GET /admin/teachers/:teacher_id/extensions/:id/confirm_delete" do
    let(:extension) { FactoryBot.create(:induction_extension, teacher:) }

    it "renders the confirm_delete template successfully" do
      get confirm_delete_admin_teacher_extension_path(teacher, extension)
      expect(response).to be_successful
    end
  end

  describe "DELETE /admin/teachers/:teacher_id/extensions/:id" do
    let!(:extension) { FactoryBot.create(:induction_extension, teacher:) }

    it "uses the manage service to delete the extension and redirects to the teacher's page" do
      manage_service = instance_double(InductionExtensions::Manage, delete!: true)
      allow(InductionExtensions::Manage).to receive(:new).and_return(manage_service)

      delete admin_teacher_extension_path(teacher, extension)

      expect(manage_service).to have_received(:delete!).with(id: extension.id.to_s)
      expect(response).to redirect_to(admin_teacher_path(teacher))
      expect(flash[:notice]).to eq("Extension was successfully deleted.")
    end

    context "when deletion fails" do
      it "redirects to the extensions index with an alert" do
        manage_service = instance_double(InductionExtensions::Manage, delete!: false)
        allow(InductionExtensions::Manage).to receive(:new).and_return(manage_service)

        delete admin_teacher_extension_path(teacher, extension)

        expect(response).to redirect_to(admin_teacher_extensions_path(teacher))
        expect(flash[:alert]).to eq("Failed to delete extension.")
      end
    end
  end
end
