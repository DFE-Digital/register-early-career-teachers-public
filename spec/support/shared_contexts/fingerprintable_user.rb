shared_examples "a fingerprintable user" do
  subject(:session_user) { described_class.new(email:, **user_props) }

  describe "#fingerprint" do
    let(:secret_hash) { "ABC123" }

    before do
      allow(OpenSSL::HMAC).to receive(:hexdigest).with(any_args).and_return(secret_hash)
    end

    it "returns a hash" do
      expect(session_user.fingerprint).to eql(secret_hash)
    end
  end
end

shared_examples "an unfingerprintable user" do
  subject(:session_user) { described_class.new(email:, **user_props) }

  describe "#fingerprint" do
    it("returns nil") { expect(session_user.fingerprint).to be_nil }
  end
end
