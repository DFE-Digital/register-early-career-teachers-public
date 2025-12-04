RSpec.describe "Sessions", type: :request do
  include ActionView::Helpers::SanitizeHelper

  describe "GET /sign-in" do
    let(:school) { FactoryBot.create(:school, urn: "123456") }

    context "when not signed in" do
      before do
        get("/sign-in")
      end

      it "renders the sign in page" do
        expect(response).to be_successful
        expect(sanitize(response.body)).to include("Select a sign in method")
      end
    end

    context "when signed in" do
      before do
        sign_in_as(:school_user, school:)
        get("/sign-in")
      end

      it "renders the sign in page" do
        expect(response).to be_successful
        expect(sanitize(response.body)).to include("Select a sign in method")
      end
    end
  end

  describe "POST /auth/:provider/callback" do
    let(:email) { Faker::Internet.email }
    let(:first_name) { Faker::Name.first_name }
    let(:last_name) { Faker::Name.last_name }
    let(:name) { [first_name, last_name].join(" ").strip }
    let(:dfe_sign_in_organisation_id) { Faker::Internet.uuid }
    let(:dfe_sign_in_user_id) { Faker::Internet.uuid }
    let(:school_urn) { "123456" }

    before do
      allow(DfESignIn::APIClient).to receive(:new).and_return(
        DfESignIn::FakeAPIClient.new(role_codes: params[:dfe_sign_in_roles])
      )
    end

    context "when using an appropriate body user" do
      let(:params) do
        {
          email:,
          name:,
          dfe_sign_in_organisation_id:,
          dfe_sign_in_user_id:,
          dfe_sign_in_roles: %w[AppropriateBodyUser],
        }
      end

      before do
        FactoryBot.create(:appropriate_body, dfe_sign_in_organisation_id:)

        mock_dfe_sign_in_provider!(uid: dfe_sign_in_user_id,
                                   email:,
                                   first_name:,
                                   last_name:,
                                   organisation_id: dfe_sign_in_organisation_id)
      end

      after do
        stop_mocking_dfe_sign_in_provider!
      end

      it "authenticates and redirects to the appropriate body home page" do
        allow(Sessions::Users::AppropriateBodyUser).to receive(:new).and_call_original
        post("/auth/dfe/callback")
        expect(Sessions::Users::AppropriateBodyUser).to have_received(:new).with(**params).once
        expect(response).to redirect_to(ab_teachers_path)
      end
    end

    context "when using a school user" do
      let(:params) do
        {
          email:,
          name:,
          school_urn:,
          dfe_sign_in_organisation_id:,
          dfe_sign_in_user_id:,
          dfe_sign_in_roles: %w[SchoolUser],
        }
      end

      let!(:school) { FactoryBot.create(:school, urn: school_urn) }

      before do
        mock_dfe_sign_in_provider!(uid: dfe_sign_in_user_id,
                                   email:,
                                   first_name:,
                                   last_name:,
                                   organisation_id: dfe_sign_in_organisation_id,
                                   organisation_urn: school_urn)
      end

      after do
        stop_mocking_dfe_sign_in_provider!
      end

      it "authenticates and redirects to the school home page" do
        allow(Sessions::Users::SchoolUser).to receive(:new).and_call_original
        post("/auth/dfe/callback")
        expect(Sessions::Users::SchoolUser).to have_received(:new).with(**params).once
        expect(response).to redirect_to(schools_ects_home_path)
      end

      context "when the feature is enabled", :prompt_for_school_induction_tutor_details do
        let!(:induction_tutor_last_nominated_in_year) { FactoryBot.create(:contract_period, year:) }
        let(:year) { Time.zone.now.year }
        let!(:school) { FactoryBot.create(:school, urn: school_urn, induction_tutor_last_nominated_in_year:, induction_tutor_name:, induction_tutor_email:) }

        context "when the school's induction tutor has never been confirmed" do
          let(:induction_tutor_name) { Faker::Name.name }
          let(:induction_tutor_email) { Faker::Internet.email }
          let(:induction_tutor_last_nominated_in_year) { nil }

          it "authenticates and redirects to the wizard" do
            allow(Sessions::Users::SchoolUser).to receive(:new).and_call_original
            post("/auth/dfe/callback")
            expect(Sessions::Users::SchoolUser).to have_received(:new).with(**params).once
            expect(response).to redirect_to(schools_confirm_existing_induction_tutor_wizard_edit_path)
          end
        end

        context "when the school's induction tutor needs to update information" do
          let(:year) { 2024 }
          let(:induction_tutor_name) { Faker::Name.name }
          let(:induction_tutor_email) { Faker::Internet.email }

          it "authenticates and redirects to the wizard" do
            FactoryBot.create(:contract_period, year: Time.zone.now.year)

            allow(Sessions::Users::SchoolUser).to receive(:new).and_call_original
            post("/auth/dfe/callback")
            expect(Sessions::Users::SchoolUser).to have_received(:new).with(**params).once
            expect(response).to redirect_to(schools_confirm_existing_induction_tutor_wizard_edit_path)
          end
        end

        context "when the school's induction tutor does not need to update information" do
          let(:year) { Time.zone.now.year }
          let(:induction_tutor_name) { Faker::Name.name }
          let(:induction_tutor_email) { Faker::Internet.email }

          it "authenticates and redirects to the school home page" do
            allow(Sessions::Users::SchoolUser).to receive(:new).and_call_original
            post("/auth/dfe/callback")
            expect(Sessions::Users::SchoolUser).to have_received(:new).with(**params).once
            expect(response).to redirect_to(schools_ects_home_path)
          end
        end
      end
    end

    context "when using a multi-role user" do
      let(:params) do
        {
          email:,
          name:,
          school_urn:,
          dfe_sign_in_organisation_id:,
          dfe_sign_in_user_id:,
          dfe_sign_in_roles: %w[SchoolUser AppropriateBodyUser]
        }
      end

      before do
        school = FactoryBot.create(:school, urn: school_urn)
        FactoryBot.create(:appropriate_body, dfe_sign_in_organisation_id:, name: school.name)

        mock_dfe_sign_in_provider!(uid: dfe_sign_in_user_id,
                                   email:,
                                   first_name:,
                                   last_name:,
                                   organisation_id: dfe_sign_in_organisation_id,
                                   organisation_urn: school_urn)
      end

      after do
        stop_mocking_dfe_sign_in_provider!
      end

      it "authenticates and redirects to the school home page" do
        allow(Sessions::Users::SchoolUser).to receive(:new).and_call_original
        post("/auth/dfe/callback")
        expect(Sessions::Users::SchoolUser).to have_received(:new).with(**params).once
        expect(response).to redirect_to(schools_ects_home_path)
      end
    end

    context "when using an appropriate body persona" do
      let(:appropriate_body_id) { FactoryBot.create(:appropriate_body).id.to_s }
      let(:params) { { email:, name:, appropriate_body_id: } }

      it "authenticates and redirects to the appropriate body home page" do
        allow(Sessions::Users::AppropriateBodyPersona).to receive(:new).and_call_original
        post("/auth/persona/callback", params:)
        expect(Sessions::Users::AppropriateBodyPersona).to have_received(:new).with(**params).once
        expect(response).to redirect_to(ab_teachers_path)
      end
    end

    context "when using a school persona" do
      let(:params) { { email:, name:, school_urn: } }
      let!(:school) { FactoryBot.create(:school, urn: school_urn) }

      it "authenticates and redirects to the school home page" do
        allow(Sessions::Users::SchoolPersona).to receive(:new).and_call_original
        post("/auth/persona/callback", params:)
        expect(Sessions::Users::SchoolPersona).to have_received(:new).with(**params).once
        expect(response).to redirect_to(schools_ects_home_path)
      end

      context "when the feature is enabled", :prompt_for_school_induction_tutor_details do
        let!(:induction_tutor_last_nominated_in_year) { FactoryBot.create(:contract_period, year:) }
        let!(:school) { FactoryBot.create(:school, urn: school_urn, induction_tutor_last_nominated_in_year:, induction_tutor_name:, induction_tutor_email:) }

        context "when the school's induction tutor has never been confirmed" do
          let(:induction_tutor_name) { Faker::Name.name }
          let(:induction_tutor_email) { Faker::Internet.email }
          let(:induction_tutor_last_nominated_in_year) { nil }

          it "authenticates and redirects to the wizard" do
            allow(Sessions::Users::SchoolPersona).to receive(:new).and_call_original
            post("/auth/persona/callback", params:)
            expect(Sessions::Users::SchoolPersona).to have_received(:new).with(**params).once
            expect(response).to redirect_to(schools_confirm_existing_induction_tutor_wizard_edit_path)
          end
        end

        context "when the school's induction tutor needs to update information" do
          let(:year) { 2024 }
          let(:induction_tutor_name) { Faker::Name.name }
          let(:induction_tutor_email) { Faker::Internet.email }

          it "authenticates and redirects to the wizard" do
            FactoryBot.create(:contract_period, year: Time.zone.now.year)

            allow(Sessions::Users::SchoolPersona).to receive(:new).and_call_original
            post("/auth/persona/callback", params:)
            expect(Sessions::Users::SchoolPersona).to have_received(:new).with(**params).once
            expect(response).to redirect_to(schools_confirm_existing_induction_tutor_wizard_edit_path)
          end
        end

        context "when the school's induction tutor does not need to update information" do
          let(:year) { Time.zone.now.year }
          let(:induction_tutor_name) { Faker::Name.name }
          let(:induction_tutor_email) { Faker::Internet.email }

          it "authenticates and redirects to the school home page" do
            allow(Sessions::Users::SchoolPersona).to receive(:new).and_call_original
            post("/auth/persona/callback", params:)
            expect(Sessions::Users::SchoolPersona).to have_received(:new).with(**params).once
            expect(response).to redirect_to(schools_ects_home_path)
          end
        end
      end
    end

    context "when using a DfE persona" do
      let(:params) { {} }

      before do
        FactoryBot.create(:user, email:, name:)
      end

      it "authenticates and redirects to the admin home page" do
        allow(Sessions::Users::DfEPersona).to receive(:new).and_call_original
        post("/auth/persona/callback", params: { dfe_staff: true, email:, name: })
        expect(Sessions::Users::DfEPersona).to have_received(:new).with(email:).once
        expect(response).to redirect_to(admin_path)
      end
    end
  end

  describe "GET /sign-out" do
    let(:session_manager) { double("Sessions::Manager", current_user: nil, end_session!: true) }

    context "when not signed in" do
      it "redirects to the sign in page" do
        allow(Sessions::Manager).to receive(:new).and_return(session_manager)
        get("/sign-out")
        expect(session_manager).to have_received(:end_session!).once
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
