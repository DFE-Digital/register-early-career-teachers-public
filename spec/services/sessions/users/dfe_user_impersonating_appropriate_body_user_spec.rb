RSpec.describe Sessions::Users::DfEUserImpersonatingAppropriateBodyUser do
  subject(:dfe_user_impersonating_appropriate_body_user) do
    Sessions::Users::DfEUserImpersonatingAppropriateBodyUser.new(
      email: user.email,
      appropriate_body_period_id: appropriate_body_period.id,
      original_type:
    )
  end

  let(:email) { "timothy.dalton@education.gov.uk" }
  let(:user) { FactoryBot.create(:user, email:, name: "Timothy Dalton") }
  let(:dfe_sign_in_organisation_id) { SecureRandom.uuid }
  let!(:appropriate_body_period) do
    FactoryBot.create(:appropriate_body_period, dfe_sign_in_organisation_id:)
  end
  let(:original_type) { "Sessions::Users::AppropriateBodyPersona" }

  it "has user type :dfe_user_impersonating_appropriate_body_user" do
    expect(Sessions::Users::DfEUserImpersonatingAppropriateBodyUser::USER_TYPE)
      .to be(:dfe_user_impersonating_appropriate_body_user)
  end

  it_behaves_like "a fingerprintable user" do
    let(:user_props) do
      {
        email: user.email,
        appropriate_body_period_id: appropriate_body_period.id,
        original_type:
      }
    end
  end

  describe "initialization" do
    it { expect(dfe_user_impersonating_appropriate_body_user.user).to eql(user) }
    it { expect(dfe_user_impersonating_appropriate_body_user.appropriate_body_period).to eql(appropriate_body_period) }
    it { expect(dfe_user_impersonating_appropriate_body_user.original_type).to eql(original_type) }
  end

  describe "#id" do
    subject(:id) { dfe_user_impersonating_appropriate_body_user.id }

    it { is_expected.to eql(user.id) }
  end

  describe "#dfe_analytics_user_id" do
    subject(:dfe_analytics_user_id) do
      dfe_user_impersonating_appropriate_body_user.dfe_analytics_user_id
    end

    it { is_expected.to eql(user.id) }
  end

  describe "#to_h" do
    subject(:to_h) { dfe_user_impersonating_appropriate_body_user.to_h }

    before { freeze_time }

    it "returns the session details" do
      expect(to_h).to eq(
        {
          "email" => email,
          "last_active_at" => Time.zone.now,
          "type" => "Sessions::Users::DfEUserImpersonatingAppropriateBodyUser",
          "original_type" => original_type,
          "appropriate_body_period_id" => appropriate_body_period.id
        }
      )
    end
  end

  describe "#expired?" do
    before { freeze_time }

    it "is expired when the max_session_idle_time has passed since the last_active_at" do
      travel_to dfe_user_impersonating_appropriate_body_user.max_session_idle_time.from_now + 1.second

      expect(dfe_user_impersonating_appropriate_body_user).to be_expired
    end

    context "when the max_session_idle_time has not passed since the last_active_at" do
      it { is_expected.not_to be_expired }
    end
  end

  describe "#rebuild_original_session" do
    subject(:rebuild_original_session) do
      dfe_user_impersonating_appropriate_body_user.rebuild_original_session
    end

    it { expect(rebuild_original_session.fetch("type")).to eql(original_type) }
    it { is_expected.not_to have_key("original_type") }
    it { is_expected.not_to have_key("appropriate_body_period_id") }
  end

  describe "user type methods" do
    it { is_expected.to be_impersonating }
    it { is_expected.to be_appropriate_body_user }
    it { is_expected.to be_dfe_user_impersonating_appropriate_body_user }
    it { is_expected.not_to be_dfe_user }
    it { is_expected.not_to be_dfe_sign_in_authorisable }
    it { is_expected.not_to be_school_user }
    it { is_expected.not_to be_dfe_user_impersonating_school_user }
  end

  describe "dfe_sign_in_user_id" do
    subject(:dfe_sign_in_user_id) do
      dfe_user_impersonating_appropriate_body_user.dfe_sign_in_user_id
    end

    it { is_expected.to be_nil }
  end
end
