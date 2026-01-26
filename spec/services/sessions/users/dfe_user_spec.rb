RSpec.describe Sessions::Users::DfEUser do
  subject(:dfe_user) { described_class.new(email:, last_active_at:) }

  let!(:user) { FactoryBot.create(:user, :admin) }
  let(:email) { user.email }
  let(:last_active_at) { 4.minutes.ago }

  it_behaves_like "a session user" do
    let(:user_props) { { email: } }
  end

  context "when there is no user with the given email" do
    let(:email) { Faker::Internet.email }

    it do
      expect { dfe_user }.to raise_error(described_class::UnknownUserEmail, email)
    end
  end

  context "when a valid email is provided with a different case" do
    let(:email) { user.email.upcase }

    it "instantiates Sessions::Users::DfEUser from the database user" do
      expect(dfe_user).to be_a(described_class)
      expect(dfe_user.email).to eq(user.email)
    end
  end

  describe "delegation" do
    it { is_expected.to delegate_method(:role).to(:user) }
    it { is_expected.to delegate_method(:admin?).to(:user) }
    it { is_expected.to delegate_method(:user_manager?).to(:user) }
    it { is_expected.to delegate_method(:finance?).to(:user) }
  end

  describe "#provider" do
    it { expect(dfe_user.provider).to be(:otp) }
  end

  describe "#user_type" do
    it { expect(dfe_user.user_type).to be(:dfe_staff_user) }
  end

  describe "#has_authorised_role?" do
    it { expect(dfe_user).to have_authorised_role }
  end

  describe "user type methods" do
    it { expect(dfe_user).to be_dfe_user }
    it { expect(dfe_user).not_to be_dfe_sign_in_authorisable }
    it { expect(dfe_user).not_to be_appropriate_body_user }
    it { expect(dfe_user).not_to be_school_user }
    it { expect(dfe_user).not_to be_dfe_user_impersonating_school_user }
  end

  describe "#event_author_params" do
    it "returns a hash with the attributes needed to record an event" do
      expect(dfe_user.event_author_params).to eql({
        author_email: dfe_user.email,
        author_id: dfe_user.id,
        author_name: dfe_user.name,
        author_type: :dfe_staff_user
      })
    end
  end

  describe "#name" do
    it "returns the full name from the user record" do
      expect(dfe_user.name).to eql(user.name)
    end
  end

  describe "#organisation_name" do
    it "returns Department for Education" do
      expect(dfe_user.organisation_name).to eq("Department for Education")
    end
  end

  describe "#to_h" do
    it "returns attributes for session storage" do
      expect(dfe_user.to_h).to eql({
        "type" => "Sessions::Users::DfEUser",
        "email" => email,
        "last_active_at" => last_active_at
      })
    end
  end

  describe "#user" do
    it "returns the User instance associated to this session user" do
      expect(dfe_user.user).to eq(user)
    end
  end
end
