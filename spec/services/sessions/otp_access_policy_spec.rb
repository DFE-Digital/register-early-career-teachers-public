RSpec.describe Sessions::OTPAccessPolicy do
  subject(:policy) { described_class.new(user:, otp_school_sign_in_enabled:) }

  let(:otp_school_sign_in_enabled) { false }
  let(:email) { "user@example.com" }
  let(:otp_school_urn) { nil }
  let(:user) { instance_double(User, email:, otp_school_urn:) }

  describe "#allowed?" do
    context "when user is nil" do
      let(:user) { nil }

      it { expect(policy.allowed?).to be(false) }
    end

    context "when user has an internal DfE email domain" do
      let(:email) { "user@education.gov.uk" }

      it "allows access regardless of flag" do
        expect(policy.allowed?).to be(true)
      end
    end

    context "when user has otp_school_urn and flag enabled" do
      let(:otp_school_sign_in_enabled) { true }
      let(:otp_school_urn) { "123456" }

      it { expect(policy.allowed?).to be(true) }
    end

    context "when user has otp_school_urn and flag disabled" do
      let(:otp_school_sign_in_enabled) { false }
      let(:otp_school_urn) { "123456" }

      it { expect(policy.allowed?).to be(false) }
    end

    context "when user has neither internal email nor otp_school_urn" do
      it { expect(policy.allowed?).to be(false) }
    end

    context "when flag enabled and user has no otp_school_urn" do
      let(:otp_school_sign_in_enabled) { true }
      let(:otp_school_urn) { nil }

      it { expect(policy.allowed?).to be(false) }
    end
  end

  describe "#denied?" do
    it "is the inverse of allowed?" do
      expect(policy.denied?).to eq(!policy.allowed?)
    end
  end

  describe "#school_sign_in?" do
    context "when flag enabled and user has otp_school_urn" do
      let(:otp_school_sign_in_enabled) { true }
      let(:otp_school_urn) { "123456" }

      it { expect(policy.school_sign_in?).to be(true) }
    end

    context "when flag disabled and user has otp_school_urn" do
      let(:otp_school_sign_in_enabled) { false }
      let(:otp_school_urn) { "123456" }

      it { expect(policy.school_sign_in?).to be(false) }
    end

    context "when flag enabled and user has no otp_school_urn" do
      let(:otp_school_sign_in_enabled) { true }
      let(:otp_school_urn) { nil }

      it { expect(policy.school_sign_in?).to be(false) }
    end
  end
end
