RSpec.describe "Admin delivery partners", type: :request do
  include_context "sign in as DfE user"

  context "impersonating a school user" do
    subject(:impersonate_school) do
      post admin_impersonate_path, params: { school_urn: }
    end

    let(:school) { FactoryBot.create(:school, urn: 999_666) }
    let(:school_urn) { school.urn }

    describe "POST /admin/impersonate" do
      it "updates the session" do
        expect { impersonate_school }
          .to change { session.dig("user_session", "type") }
          .from("Sessions::Users::DfEPersona")
          .to("Sessions::Users::DfEUserImpersonatingSchoolUser")
          .and change { session.dig("user_session", "original_type") }
          .from(nil)
          .to("Sessions::Users::DfEPersona")
      end

      it "redirects to the school ects index" do
        expect(impersonate_school).to redirect_to(schools_ects_home_path)
      end

      it "cannot access admin pages" do
        impersonate_school

        get admin_teachers_path

        expect(response).to have_http_status(:unauthorized)
      end

      context "when the school does not exist" do
        let(:school_urn) { "something_impossible" }

        it "errors with SchoolDoesNotExist" do
          expect { impersonate_school }
            .to raise_error(Sessions::ImpersonateOrganisationUser::SchoolDoesNotExist)
        end
      end
    end

    describe "DELETE /admin/impersonate" do
      it "reverts the session" do
        impersonate_school

        expect { delete admin_impersonate_path }
          .to change { session.dig("user_session", "type") }
          .from("Sessions::Users::DfEUserImpersonatingSchoolUser")
          .to("Sessions::Users::DfEPersona")
          .and change { session.dig("user_session", "original_type") }
          .from("Sessions::Users::DfEPersona")
          .to(nil)
      end

      it "errors if a non-impersonating user tries to stop impersonating" do
        expect { delete admin_impersonate_path }
          .to raise_error(Admin::ImpersonationController::InvalidUserType)
      end

      it "redirects to the school ects index" do
        impersonate_school

        expect(delete(admin_impersonate_path))
          .to redirect_to(admin_school_overview_path(school_urn))
      end

      it "can access admin pages" do
        impersonate_school
        delete admin_impersonate_path

        get admin_teachers_path

        expect(response).to have_http_status(:ok)
      end

      it "cannot access admin pages if session has expired" do
        impersonate_school
        travel_to 1.second.after(Rails.configuration.max_session_idle_time.from_now)
        delete admin_impersonate_path

        get admin_teachers_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  context "impersonating an appropriate body user" do
    subject(:impersonate_appropriate_body) do
      post admin_impersonate_path, params: { appropriate_body_period_id: }
    end

    let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
    let(:appropriate_body_period_id) { appropriate_body_period.id }

    describe "POST /admin/impersonate" do
      it "updates the session" do
        expect { impersonate_appropriate_body }
          .to change { session.dig("user_session", "type") }
          .from("Sessions::Users::DfEPersona")
          .to("Sessions::Users::DfEUserImpersonatingAppropriateBodyUser")
          .and change { session.dig("user_session", "original_type") }
          .from(nil)
          .to("Sessions::Users::DfEPersona")
      end

      it "redirects to the appropriate bodies teachers path" do
        expect(impersonate_appropriate_body).to redirect_to(ab_teachers_path)
      end

      it "cannot access admin pages" do
        impersonate_appropriate_body

        get admin_teachers_path

        expect(response).to have_http_status(:unauthorized)
      end

      context "when the appropriate body does not exist" do
        let(:appropriate_body_period_id) { "something_impossible" }

        it "errors with AppropriateBodyDoesNotExist" do
          expect { impersonate_appropriate_body }
            .to raise_error(Sessions::ImpersonateOrganisationUser::AppropriateBodyDoesNotExist)
        end
      end
    end

    describe "DELETE /admin/impersonate" do
      it "reverts the session" do
        impersonate_appropriate_body

        expect { delete admin_impersonate_path }
          .to change { session.dig("user_session", "type") }
          .from("Sessions::Users::DfEUserImpersonatingAppropriateBodyUser")
          .to("Sessions::Users::DfEPersona")
          .and change { session.dig("user_session", "original_type") }
          .from("Sessions::Users::DfEPersona")
          .to(nil)
      end

      it "errors if a non-impersonating user tries to stop impersonating" do
        expect { delete admin_impersonate_path }
          .to raise_error(Admin::ImpersonationController::InvalidUserType)
      end

      it "redirects to the appropriate bodies teachers path" do
        impersonate_appropriate_body

        expect(delete(admin_impersonate_path))
          .to redirect_to(admin_appropriate_body_path(appropriate_body_period_id))
      end

      it "can access admin pages" do
        impersonate_appropriate_body
        delete admin_impersonate_path

        get admin_teachers_path

        expect(response).to have_http_status(:ok)
      end

      it "cannot access admin pages if session has expired" do
        impersonate_appropriate_body
        travel_to 1.second.after(Rails.configuration.max_session_idle_time.from_now)
        delete admin_impersonate_path

        get admin_teachers_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end
end
