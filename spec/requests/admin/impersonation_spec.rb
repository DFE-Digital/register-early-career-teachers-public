RSpec.describe "Admin delivery partners", type: :request do
  include_context "sign in as DfE user"

  let(:school) { FactoryBot.create(:school, urn: 999_666) }

  describe "POST /admin/impersonate" do
    it "updates the session" do
      expect(session.dig("user_session", "type")).to eql("Sessions::Users::DfEPersona")

      post admin_impersonate_path, params: { school_urn: school.urn }

      expect(session.dig("user_session", "type")).to eql("Sessions::Users::DfEUserImpersonatingSchoolUser")
      expect(session.dig("user_session", "original_type")).to eql("Sessions::Users::DfEPersona")
    end

    it "redirects to the school ects index" do
      expect(post(admin_impersonate_path, params: { school_urn: school.urn })).to redirect_to(schools_ects_home_path)
    end

    context "when the school does not exist" do
      it "errors with SchoolDoesNotExist" do
        expect { post admin_impersonate_path, params: { school_urn: 999_888 } }.to raise_error(Sessions::ImpersonateSchoolUser::SchoolDoesNotExist)
      end
    end
  end

  describe "DELETE /admin/impersonate" do
    it "reverts the session" do
      post admin_impersonate_path, params: { school_urn: school.urn }

      expect(session.dig("user_session", "type")).to eql("Sessions::Users::DfEUserImpersonatingSchoolUser")
      expect(session.dig("user_session", "original_type")).to eql("Sessions::Users::DfEPersona")

      delete admin_impersonate_path, params: { school_urn: school.urn }

      expect(session.dig("user_session", "type")).to eql("Sessions::Users::DfEPersona")
      expect(session.dig("user_session", "original_type")).to be_nil
    end

    it "errors if a non-impersonating user tries to stop impersonating" do
      expect { delete admin_impersonate_path, params: { school_urn: school.urn } }.to raise_error(Admin::ImpersonationController::InvalidUserType)
    end

    it "redirects to the school ects index" do
      post admin_impersonate_path, params: { school_urn: school.urn }

      expect(delete(admin_impersonate_path, params: { school_urn: school.urn })).to redirect_to(admin_school_overview_path(school.urn))
    end
  end
end
