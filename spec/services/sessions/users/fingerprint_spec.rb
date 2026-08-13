class SomeUser
  include Sessions::Users::Fingerprint

  def dfe_analytics_user_id = "abc123"
end

describe "Fingerprinting users" do
  subject { SomeUser.new }

  let(:secret) { "qwerty" }

  describe "#fingerprint" do
    context "when no key is passed in" do
      before do
        allow(OpenSSL::HMAC).to receive(:hexdigest).with("SHA256", secret, "abc123").and_return("SECRET")
        allow(Rails.application).to receive(:secret_key_base).and_return("qwerty")
      end

      it "defaults to Rails' secret_key_base" do
        subject.fingerprint
        expect(OpenSSL::HMAC).to have_received(:hexdigest).with("SHA256", secret, "abc123")
      end

      it "returns the result of #hexdigest" do
        expect(subject.fingerprint).to eql("SECRET")
      end
    end

    context "when a key is passed in" do
      let(:new_secret) { "xyz" }

      before do
        allow(OpenSSL::HMAC).to receive(:hexdigest).with("SHA256", new_secret, "abc123").and_return("CONFIDENTIAL")
        allow(Rails.application).to receive(:secret_key_base).and_return("qwerty")
      end

      it "uses the provided key" do
        subject.fingerprint(new_secret)
        expect(OpenSSL::HMAC).to have_received(:hexdigest).with("SHA256", new_secret, "abc123")
      end

      it "returns the result of #hexdigest" do
        expect(subject.fingerprint(new_secret)).to eql("CONFIDENTIAL")
      end
    end
  end
end
