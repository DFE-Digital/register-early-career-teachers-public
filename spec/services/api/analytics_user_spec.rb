describe API::AnalyticsUser do
  let(:analytics_user) { API::AnalyticsUser.new(lead_provider) }
  let(:lead_provider) { FactoryBot.build(:lead_provider, short_name: "short") }

  describe "#lead_provider" do
    subject { analytics_user.lead_provider }

    it { is_expected.to eq(lead_provider) }
  end

  describe "#name" do
    subject { analytics_user.name }

    it { is_expected.to eq(lead_provider.name) }
  end

  describe "#fingerprint" do
    subject { analytics_user.fingerprint }

    it { is_expected.to eq(lead_provider.short_name) }
  end
end
