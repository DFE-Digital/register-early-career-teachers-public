RSpec.describe Sessions::Users::OTPSchoolUser do
  subject(:otp_school_user) { described_class.new(email:, name:, school_urn:, last_active_at:) }

  let!(:school) { FactoryBot.create(:school) }
  let(:email) { "school_user@email.com" }
  let(:last_active_at) { 4.minutes.ago }
  let(:name) { "Kakarot" }
  let(:school_urn) { school.urn }

  it_behaves_like "a session user" do
    let(:user_props) { { email:, name:, school_urn: } }
  end

  context "when the gias school exists but no school record has been linked yet" do
    let(:gias_school) { FactoryBot.create(:gias_school, :open, :state_school_type) }
    let(:school_urn) { gias_school.urn }

    it "builds the user from the gias school" do
      expect(otp_school_user.school).to be_nil
      expect(otp_school_user.gias_school).to eq(gias_school)
      expect(otp_school_user.organisation_name).to eq(gias_school.name)
    end
  end

  context "when no school or gias school is found" do
    let(:school_urn) { "A123456" }

    it "raises an error" do
      expect { otp_school_user }.to raise_error(described_class::UnknownOrganisationURN, school_urn)
    end
  end

  describe "#provider" do
    it { expect(otp_school_user.provider).to be(:otp) }
  end

  describe "#user_type" do
    it { expect(otp_school_user.user_type).to be(:school_user) }
  end

  describe "user type methods" do
    it { expect(otp_school_user).to be_school_user }
    it { expect(otp_school_user).not_to be_dfe_sign_in_authorisable }
    it { expect(otp_school_user).not_to be_dfe_user }
    it { expect(otp_school_user).not_to be_appropriate_body_user }
    it { expect(otp_school_user).not_to be_dfe_user_impersonating_school_user }
  end

  describe "#event_author_params" do
    it "returns a hash with the attributes needed to record an event" do
      expect(otp_school_user.event_author_params).to eql({
        author_email: otp_school_user.email,
        author_name: otp_school_user.name,
        author_type: :school_user
      })
    end
  end

  describe "#name" do
    it "returns the full name of the user" do
      expect(otp_school_user.name).to eql(name)
    end
  end

  describe "#organisation_name" do
    it "returns the name of the school associated to the user" do
      expect(otp_school_user.organisation_name).to eq(school.name)
    end
  end

  describe "#school" do
    it "returns the school of the user" do
      expect(otp_school_user.school).to eql(school)
    end
  end

  describe "#school_urn" do
    it "returns the urn of the school of the user" do
      expect(otp_school_user.school_urn).to eql(school.urn)
    end
  end

  describe "#sign_out_path" do
    it "returns the OTP sign out path" do
      expect(otp_school_user.sign_out_path).to eq("/sign-out")
    end
  end

  describe "#to_h" do
    it "returns attributes for session storage" do
      expect(otp_school_user.to_h).to eql({
        "type" => "Sessions::Users::OTPSchoolUser",
        "email" => email,
        "name" => name,
        "last_active_at" => last_active_at,
        "school_urn" => school.urn
      })
    end
  end

  describe "#user" do
    it { expect(otp_school_user.user).to be_nil }
  end
end
