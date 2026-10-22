RSpec.describe "DfE Sign-in access requests" do
  describe "POST #create" do
    subject(:access_request) do
      post sessions_access_request_path
      response
    end

    let(:dfe_api_client) { DfESignIn::FakeAPIClient.new }

    before do
      allow(DfESignIn::APIClient).to receive(:new).and_return(dfe_api_client)
    end

    after { stop_mocking_dfe_sign_in_provider! }

    context "when there are no organisation details in the session" do
      it { is_expected.to have_http_status(:not_found) }

      it "does not make an access request" do
        expect { access_request }
          .not_to have_enqueued_job(DfESignIn::AccessRequestJob)
      end
    end

    context "when the organisation details in the session don't match any " \
            "organisations" do
      let(:organisation_id) { SecureRandom.uuid }
      let(:user_id) { SecureRandom.uuid }

      before do
        mock_dfe_sign_in_provider!(
          email: Faker::Internet.email,
          uid: user_id,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          organisation_id:,
          organisation_name: "A missing School"
        )
        post "/auth/dfe/callback"
      end

      it { is_expected.to have_http_status(:not_found) }

      it "does not make an access request" do
        expect { access_request }
          .not_to have_enqueued_job(DfESignIn::AccessRequestJob)
      end
    end

    context "when the organisation details in the session match a school" do
      let!(:school) { FactoryBot.create(:school, :with_dsi) }
      let!(:school_user_role) do
        FactoryBot.create(:dfe_sign_in_role, :school_user)
      end
      let(:organisation_id) { school.dfe_sign_in_organisation.uuid }
      let(:user_id) { SecureRandom.uuid }

      before do
        mock_dfe_sign_in_provider!(
          email: Faker::Internet.email,
          uid: user_id,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          organisation_id:,
          organisation_urn: school.urn,
          organisation_name: school.name
        )
        post "/auth/dfe/callback"
      end

      it { is_expected.to redirect_to(confirmation_sessions_access_request_path) }

      it "makes an access request" do
        expect { access_request }
          .to have_enqueued_job(DfESignIn::AccessRequestJob)
          .with(
            organisation_id:,
            user_id:,
            role_ids: [school_user_role.dfe_sign_in_role_id]
          )
      end

      it "removes the organisation details from the session" do
        expect { access_request }
          .to change { session[:invalid_organisation_details] }
          .from(
            {
              dfe_sign_in_organisation_id: organisation_id,
              dfe_sign_in_user_id: user_id,
              dfe_sign_in_organisation_name: school.name,
              dfe_sign_in_organisation_urn: school.urn
            }
          )
          .to(nil)
      end

      context "when there are subsequent requests" do
        before { post sessions_access_request_path }

        it { is_expected.to have_http_status(:not_found) }

        it "does not make an access request" do
          expect { access_request }
            .not_to have_enqueued_job(DfESignIn::AccessRequestJob)
        end
      end
    end

    context "when the organisation details in the session match an " \
            "appropriate body" do
      let!(:appropriate_body_period) do
        FactoryBot.create(:appropriate_body_period, :with_dsi)
      end
      let!(:appropriate_body_user_role) do
        FactoryBot.create(:dfe_sign_in_role, :appropriate_body_user)
      end
      let(:organisation_id) do
        appropriate_body_period.dfe_sign_in_organisation.uuid
      end
      let(:user_id) { SecureRandom.uuid }

      before do
        mock_dfe_sign_in_provider!(
          email: Faker::Internet.email,
          uid: user_id,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          organisation_id:,
          organisation_name: appropriate_body_period.name
        )
        post "/auth/dfe/callback"
      end

      it { is_expected.to redirect_to(confirmation_sessions_access_request_path) }

      it "makes an access request" do
        expect { access_request }
          .to have_enqueued_job(DfESignIn::AccessRequestJob)
          .with(
            organisation_id:,
            user_id:,
            role_ids: [appropriate_body_user_role.dfe_sign_in_role_id]
          )
      end

      it "removes the organisation details from the session" do
        expect { access_request }
          .to change { session[:invalid_organisation_details] }
          .from(
            {
              dfe_sign_in_organisation_id: organisation_id,
              dfe_sign_in_user_id: user_id,
              dfe_sign_in_organisation_name: appropriate_body_period.name,
              dfe_sign_in_organisation_urn: nil
            }
          )
          .to(nil)
      end

      context "when there are subsequent requests" do
        before { post sessions_access_request_path }

        it { is_expected.to have_http_status(:not_found) }

        it "does not make an access request" do
          expect { access_request }
            .not_to have_enqueued_job(DfESignIn::AccessRequestJob)
        end
      end
    end

    context "when the organisation details in the session match a school " \
            "that is an appropriate body" do
      let!(:school) { FactoryBot.create(:school, :with_dsi) }
      let!(:appropriate_body_period) do
        FactoryBot.create(
          :appropriate_body_period,
          :with_dsi,
          dfe_sign_in_organisation: school.dfe_sign_in_organisation
        )
      end
      let!(:school_user_role) do
        FactoryBot.create(:dfe_sign_in_role, :school_user)
      end
      let!(:appropriate_body_user_role) do
        FactoryBot.create(:dfe_sign_in_role, :appropriate_body_user)
      end
      let(:organisation_id) { school.dfe_sign_in_organisation.uuid }
      let(:user_id) { SecureRandom.uuid }

      before do
        mock_dfe_sign_in_provider!(
          email: Faker::Internet.email,
          uid: user_id,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          organisation_id:,
          organisation_urn: school.urn,
          organisation_name: school.name
        )
        post "/auth/dfe/callback"
      end

      it { is_expected.to redirect_to(confirmation_sessions_access_request_path) }

      it "makes an access request" do
        expect { access_request }
          .to have_enqueued_job(DfESignIn::AccessRequestJob)
          .with(
            organisation_id:,
            user_id:,
            role_ids: [
              school_user_role.dfe_sign_in_role_id,
              appropriate_body_user_role.dfe_sign_in_role_id
            ]
          )
      end

      it "removes the organisation details from the session" do
        expect { access_request }
          .to change { session[:invalid_organisation_details] }
          .from(
            {
              dfe_sign_in_organisation_id: organisation_id,
              dfe_sign_in_user_id: user_id,
              dfe_sign_in_organisation_name: school.name,
              dfe_sign_in_organisation_urn: school.urn
            }
          )
          .to(nil)
      end

      context "when there are subsequent requests" do
        before { post sessions_access_request_path }

        it { is_expected.to have_http_status(:not_found) }

        it "does not make an access request" do
          expect { access_request }
            .not_to have_enqueued_job(DfESignIn::AccessRequestJob)
        end
      end
    end
  end
end
