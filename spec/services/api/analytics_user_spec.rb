describe API::AnalyticsUser do
  subject { API::AnalyticsUser.new(lead_provider) }

  let(:lead_provider) { FactoryBot.build(:lead_provider, id: 123) }

  describe "#lead_provider" do
    it "returns the provided lead_provider" do
      expect(subject.lead_provider).to eql(lead_provider)
    end
  end

  describe "#name" do
    it "returns the lead provider's name" do
      expect(subject.name).to be(lead_provider.name)
    end
  end

  describe "#fingerprint" do
    it "returns lead_provider's fingerprint" do
      expect(subject.fingerprint).to be(123)
    end
  end
end
