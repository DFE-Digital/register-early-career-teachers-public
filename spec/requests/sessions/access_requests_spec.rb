RSpec.describe "DfE Sign-in access requests" do
  describe "POST #create" do
    subject(:access_request) do
      post sessions_access_request_path
      response
    end

    let(:dfe_api_client) do
      DfESignIn::FakeAPIClient.new(role_codes: %w[UnknownRole])
    end

    before do
      allow(DfESignIn::APIClient).to receive(:new).and_return(dfe_api_client)
    end

    after { stop_mocking_dfe_sign_in_provider! }

    context "when there are no organisation details in the session" do
      it { is_expected.to redirect_to("/404") }

      it "does not make an access request" do
        expect { access_request }
          .not_to have_enqueued_job(DfESignIn::AccessRequestJob)
      end
    end

    context "when the organisation details in the session don't match any organisations" do
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

      it { is_expected.to redirect_to("/404") }

      it "does not make an access request" do
        expect { access_request }
          .not_to have_enqueued_job(DfESignIn::AccessRequestJob)
      end
    end

    context "when the organisation details in the session match a school" do
      let!(:school) { FactoryBot.create(:school, :with_dsi) }
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

      it "makes an access request" do
        expect { access_request }
          .to have_enqueued_job(DfESignIn::AccessRequestJob)
          .with(organisation_id:, user_id:, role_ids: %w[SchoolUser])
      end
    end

    context "when the organisation details in the session match an appropriate body" do
      let!(:appropriate_body_period) do
        FactoryBot.create(:appropriate_body_period, :with_dsi)
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

      it "makes an access request" do
        expect { access_request }
          .to have_enqueued_job(DfESignIn::AccessRequestJob)
          .with(organisation_id:, user_id:, role_ids: %w[AppropriateBodyUser])
      end
    end

    context "when the organisation details in the session match a school that is an appropriate body" do
      let!(:school) { FactoryBot.create(:school, :with_dsi) }
      let!(:appropriate_body_period) do
        FactoryBot.create(
          :appropriate_body_period,
          :with_dsi,
          dfe_sign_in_organisation: school.dfe_sign_in_organisation
        )
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

      it "makes an access request" do
        expect { access_request }
          .to have_enqueued_job(DfESignIn::AccessRequestJob)
          .with(organisation_id:, user_id:, role_ids: %w[SchoolUser AppropriateBodyUser])
      end
    end
  end
end
