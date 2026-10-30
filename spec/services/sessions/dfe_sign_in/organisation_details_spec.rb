RSpec.describe Sessions::DfESignIn::OrganisationDetails do
  subject(:organisation_details) { described_class.new(session_details) }

  let(:session_details) do
    {
      "dfe_sign_in_organisation_id" => dfe_sign_in_organisation_id,
      "dfe_sign_in_organisation_urn" => dfe_sign_in_organisation_urn,
      "dfe_sign_in_organisation_name" => dfe_sign_in_organisation_name,
      "dfe_sign_in_user_id" => dfe_sign_in_user_id
    }
  end

  let(:dfe_sign_in_organisation_id) { SecureRandom.uuid }
  let(:dfe_sign_in_organisation_urn) { "123456" }
  let(:dfe_sign_in_organisation_name) { "Test School" }
  let(:dfe_sign_in_user_id) { SecureRandom.uuid }

  describe "#missing?" do
    context "when details are blank" do
      let(:session_details) { nil }

      it { is_expected.to be_missing }
    end

    context "when details are empty" do
      let(:session_details) { {} }

      it { is_expected.to be_missing }
    end

    context "when details are present" do
      it { is_expected.not_to be_missing }
    end
  end

  describe "#access_requestable?" do
    context "when details are blank" do
      let(:session_details) { nil }

      it { is_expected.not_to be_access_requestable }
    end

    context "when there are no matching roles" do
      it { is_expected.not_to be_access_requestable }
    end

    context "when there are matching roles" do
      let!(:school_user_role) do
        FactoryBot.create(:dfe_sign_in_role, :school_user)
      end
      let!(:school) do
        FactoryBot.create(:school, urn: dfe_sign_in_organisation_urn)
      end

      it { is_expected.to be_access_requestable }
    end
  end

  describe "#name" do
    subject(:name) { organisation_details.name }

    context "when the organisation name is missing" do
      before { session_details.delete("dfe_sign_in_organisation_name") }

      it { is_expected.to be_nil }
    end

    context "when the organisation name is present" do
      it { is_expected.to eq(dfe_sign_in_organisation_name) }
    end
  end

  describe "#organisation_id" do
    subject(:organisation_id) { organisation_details.organisation_id }

    context "when the organisation id is missing" do
      before { session_details.delete("dfe_sign_in_organisation_id") }

      it { is_expected.to be_nil }
    end

    context "when the organisation id is present" do
      it { is_expected.to eq(dfe_sign_in_organisation_id) }
    end
  end

  describe "#user_id" do
    subject(:user_id) { organisation_details.user_id }

    context "when the user id is missing" do
      before { session_details.delete("dfe_sign_in_user_id") }

      it { is_expected.to be_nil }
    end

    context "when the user id is present" do
      it { is_expected.to eq(dfe_sign_in_user_id) }
    end
  end

  describe "#role_ids" do
    subject(:role_ids) { organisation_details.role_ids }

    let!(:school_user_role) do
      FactoryBot.create(:dfe_sign_in_role, :school_user)
    end
    let!(:appropriate_body_user_role) do
      FactoryBot.create(:dfe_sign_in_role, :appropriate_body_user)
    end

    context "when the organisation urn matches a school" do
      let!(:school) do
        FactoryBot.create(:school, urn: dfe_sign_in_organisation_urn)
      end

      it { is_expected.to contain_exactly(school_user_role.dfe_sign_in_role_id) }
    end

    context "when the organisation id matches an appropriate body period" do
      let!(:appropriate_body_period) do
        FactoryBot.create(:appropriate_body_period, dfe_sign_in_organisation_id:)
      end

      it { is_expected.to contain_exactly(appropriate_body_user_role.dfe_sign_in_role_id) }
    end

    context "when the organisation details match both a school and an " \
            "appropriate body period" do
      let!(:school) do
        FactoryBot.create(:school, urn: dfe_sign_in_organisation_urn)
      end
      let!(:appropriate_body_period) do
        FactoryBot.create(:appropriate_body_period, dfe_sign_in_organisation_id:)
      end

      it "returns both school_user and appropriate_body_user role ids" do
        expect(role_ids).to contain_exactly(
          school_user_role.dfe_sign_in_role_id,
          appropriate_body_user_role.dfe_sign_in_role_id
        )
      end
    end

    context "when the organisation details match neither a school nor an "\
            "appropriate body period" do
      it { is_expected.to be_empty }
    end
  end
end
