require "rails_helper"

RSpec.describe "Admin::Teachers#show", type: :request do
  include ActionView::Helpers::SanitizeHelper

  let(:teacher) { FactoryBot.create(:teacher) }
  let!(:induction_period) { FactoryBot.create(:induction_period, teacher: teacher, finished_on: nil) }

  describe "GET /admin/teachers/:trn" do
    it "redirects to sign-in" do
      get admin_teacher_path(teacher)
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      before do
        sign_in_as(:appropriate_body_user, appropriate_body: FactoryBot.create(:appropriate_body))
      end

      it "requires authorisation" do
        get admin_teacher_path(teacher)
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      before do
        sign_in_as(:dfe_user, user: FactoryBot.create(:user, :admin))
      end

      it "returns http success" do
        get admin_teacher_path(teacher)
        expect(response).to have_http_status(:success)
      end

      it "displays teacher information" do
        get admin_teacher_path(teacher)
        expect(response.body).to include(teacher.trn)
        expect(response.body).to include(CGI.escape_html(Teachers::Name.new(teacher).full_name))
      end

      context "when teacher has migration failures" do
        before do
          MigrationFailure.create!(parent_type: "Teacher", parent_id: teacher.id, failure_message: "foo", item: { foo: :bar }, data_migration_id: 1)
        end

        it "displays migration warning" do
          get admin_teacher_path(teacher)
          expect(sanitize(response.body)).to include("Some of this teacher's records could not be migrated")
        end
      end

      context "when accessed from index page" do
        it "includes page parameter in backlink" do
          get admin_teacher_path(teacher, page: 2)
          expect(response.body).to include(admin_teachers_path(page: 2))
        end
      end
    end
  end
end
