describe Sessions::Users::DfEUserImpersonatingSchoolUser do # rubocop:disable RSpec/SpecFilePathFormat
  subject(:dfe_user_impersonating_school_user) { Sessions::Users::DfEUserImpersonatingSchoolUser.new(email: user.email, school_urn:, original_type:) }

  let(:email) { "timothy.dalton@education.gov.uk" }
  let(:user) { FactoryBot.create(:user, email:, name: "Timothy Dalton") }
  let(:school_urn) { 100_007 }
  let!(:school) { FactoryBot.create(:school, urn: school_urn) }
  let(:original_type) { "Sessions::Users::SchoolPersona" }

  it "has user type :dfe_user_impersonating_school_user" do
    expect(Sessions::Users::DfEUserImpersonatingSchoolUser::USER_TYPE).to be(:dfe_user_impersonating_school_user)
  end

  it_behaves_like "a fingerprintable user" do
    let(:user_props) { { email: user.email, school_urn: school.urn, original_type: } }
  end

  describe "initialization" do
    it { expect(dfe_user_impersonating_school_user.user).to eql(user) }
    it { expect(dfe_user_impersonating_school_user.school).to eql(school) }
    it { expect(dfe_user_impersonating_school_user.original_type).to eql(original_type) }
  end

  describe "#id" do
    it { expect(dfe_user_impersonating_school_user.id).to eql(user.id) }
  end

  describe "#dfe_analytics_user_id" do
    it { expect(dfe_user_impersonating_school_user.dfe_analytics_user_id).to eql(user.id) }
  end

  describe "#to_h" do
    it "returns the session details" do
      expect(dfe_user_impersonating_school_user.to_h.except("last_active_at")).to eq(
        {
          "email" => email,
          "type" => "Sessions::Users::DfEUserImpersonatingSchoolUser",
          "original_type" => original_type,
          "school_urn" => school_urn
        }
      )
    end
  end

  describe "#rebuild_original_session" do
    it "switches the current type for the original type" do
      expect(dfe_user_impersonating_school_user.rebuild_original_session.fetch("type")).to eql(original_type)
    end

    it "does not include the original type" do
      expect(dfe_user_impersonating_school_user.rebuild_original_session).not_to have_key("original_type")
    end

    it "does not include the school_urn" do
      expect(dfe_user_impersonating_school_user.rebuild_original_session).not_to have_key("school_urn")
    end
  end

  describe "user type methods" do
    it { expect(dfe_user_impersonating_school_user).to be_school_user }
    it { expect(dfe_user_impersonating_school_user).to be_dfe_user_impersonating_school_user }
    it { expect(dfe_user_impersonating_school_user).not_to be_dfe_user }
    it { expect(dfe_user_impersonating_school_user).not_to be_dfe_sign_in_authorisable }
    it { expect(dfe_user_impersonating_school_user).not_to be_appropriate_body_user }
  end
end
