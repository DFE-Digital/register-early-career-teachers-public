describe API::AnalyticsUser do
  let(:analytics_user) { API::AnalyticsUser.new(lead_provider) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }

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

    it { expect(subject).to eq(lead_provider.id) }
  end
end
