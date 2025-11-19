RSpec.describe Sessions::Users::SchoolUser do
  subject(:school_user) do
    described_class.new(
      email:,
      name:,
      school_urn:,
      dfe_sign_in_organisation_id:,
      dfe_sign_in_user_id:,
      dfe_sign_in_roles:,
      last_active_at:
    )
  end

  let!(:school) { FactoryBot.create(:school) }
  let(:email) { "school_user@email.com" }
  let(:last_active_at) { 4.minutes.ago }
  let(:name) { "Christopher Lee" }
  let(:dfe_sign_in_organisation_id) { Faker::Internet.uuid }
  let(:dfe_sign_in_user_id) { Faker::Internet.uuid }
  let(:dfe_sign_in_roles) { %w[SchoolUser] }
  let(:school_urn) { school.urn }

  it_behaves_like "a session user" do
    let(:user_props) do
      { email:, name:, school_urn: school.urn, dfe_sign_in_organisation_id:, dfe_sign_in_user_id:, dfe_sign_in_roles: }
    end
  end

  context "when no school is found" do
    let(:school_urn) { "A123456" }

    it do
      expect { subject }.to raise_error(described_class::UnknownOrganisationURN, school_urn)
    end
  end

  describe "#provider" do
    it { expect(school_user.provider).to be(:dfe_sign_in) }
  end

  describe "#user_type" do
    it { expect(school_user.user_type).to be(:school_user) }
  end

  describe "#appropriate_body_user?" do
    it { expect(school_user).not_to be_appropriate_body_user }
  end

  describe "#has_authorised_role?" do
    it { expect(school_user).to have_authorised_role }
  end

  describe "#dfe_sign_in_organisation_id" do
    it "returns the id of the organisation of the user in DfE SignIn" do
      expect(school_user.dfe_sign_in_organisation_id).to eql(dfe_sign_in_organisation_id)
    end
  end

  describe "#dfe_sign_in_user_id" do
    it "returns the id of the user in DfE SignIn" do
      expect(school_user.dfe_sign_in_user_id).to eql(dfe_sign_in_user_id)
    end
  end

  describe "user type methods" do
    it { expect(school_user).to be_school_user }
    it { expect(school_user).to be_dfe_sign_in_authorisable }
    it { expect(school_user).not_to be_dfe_user }
    it { expect(school_user).not_to be_appropriate_body_user }
    it { expect(school_user).not_to be_dfe_user_impersonating_school_user }
  end

  describe "#event_author_params" do
    it "returns a hash with the attributes needed to record an event" do
      expect(school_user.event_author_params).to eql({
        author_email: school_user.email,
        author_name: school_user.name,
        author_type: :school_user
      })
    end
  end

  describe "#name" do
    it "returns the full name of the user" do
      expect(school_user.name).to eql(name)
    end
  end

  describe "#organisation_name" do
    it "returns the name of the school associated to the user" do
      expect(school_user.organisation_name).to eq(school.name)
    end
  end

  describe "#school" do
    it "returns the school of the user" do
      expect(school_user.school).to eql(school)
    end
  end

  describe "#school_urn" do
    it "returns the urn of the school of the user" do
      expect(school_user.school_urn).to eql(school.urn)
    end
  end

  describe "#to_h" do
    it "returns attributes for session storage" do
      expect(school_user.to_h).to eql({
        "type" => "Sessions::Users::SchoolUser",
        "email" => email,
        "name" => name,
        "last_active_at" => last_active_at,
        "last_active_role" => "SchoolUser",
        "school_urn" => school.urn,
        "dfe_sign_in_organisation_id" => dfe_sign_in_organisation_id,
        "dfe_sign_in_user_id" => dfe_sign_in_user_id,
        "dfe_sign_in_roles" => dfe_sign_in_roles
      })
    end
  end

  describe "#user" do
    it { expect(school_user.user).to be_nil }
  end
end
